#encoding: utf-8
class MessagesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_subject_user, only: [:new, :create]
  before_filter :author, only: [:edit, :update]
  before_filter :admin_user, only: [:destroy]
  before_filter :valid_chapter
  before_filter :online_chapter
  before_filter :notskin_user, only: [:create, :update]

  # Créer un message
  def new
    @message = Message.new
  end

  # Editer un message
  def edit
  end

  # Créer un message 2
  def create
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    @message = Message.new(params[:message])
    @message.user = current_user.sk
    @message.subject = @subject

    # On vérifie qu'il n'y a pas eu de nouveau message entre
    lastid = -1
    lastmessage = @subject.messages.order("id DESC").first
    if !lastmessage.nil?
      lastid = lastmessage.id
    end

    if lastid != params[:lastmessage].to_i
      flash.now[:danger] = "Un nouveau message a été posté avant le vôtre! Veuillez en prendre connaissance ci-dessous avant de poster votre message."
      render 'new' and return
    end

    # Pièces jointes une par une
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Messagefile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          flash.now[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          render 'new' and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    # On vérifie que les pièces jointes ne sont pas trop grosses
    if totalsize > 5.megabytes
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end

      flash.now[:danger] = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)."
      render 'new' and return
    end

    # Si le message a bien été sauvé
    if @message.save

      # On enregistre les pièces jointes
      j = 1
      while j < i do
        attach[j-1].message = @message
        attach[j-1].save
        j = j+1
      end

      # Envoi d'un mail aux utilisateurs suivant le sujet
      @subject.following_users.each do |u|
        if u != current_user
          if (@subject.admin && !u.admin) || (@subject.wepion && !u.wepion && !u.admin)
            # Ce n'est pas vraiment normal qu'il suive ce sujet
          else
            UserMailer.new_followed_message(u.id, @subject.id, current_user.sk.name, @message.content, @message.id).deliver
          end
        end
      end

      @subject.lastcomment = DateTime.current
      @subject.save

      tot = @subject.messages.count
      page = [0,((tot-1)/10).floor].max + 1
      
      if current_user.sk.admin?
		    if params.has_key?(:groupeA)
		    	User.where(:group => "A").each do |u|
		    		UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, @message.id).deliver
		    	end
		    end
		    if params.has_key?(:groupeB)
		    	User.where(:group => "B").each do |u|
		    		UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, @message.id).deliver
		    	end
		    end
		  end
      
      flash[:success] = "Votre message a bien été posté."
      
      redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => q)

    # Si il y a eu un problème : on supprime les pièces jointes
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      render 'new'
    end
  end

  # Editer un message 2
  def update
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    # Si la modification du message réussit
    if @message.update_attributes(params[:message])

      # On s'occupe des pièces jointes
      totalsize = 0

      @message.messagefiles.each do |sf|
        if params["prevfile#{sf.id}".to_sym].nil?
          sf.file.destroy
          sf.destroy
        else
          totalsize = totalsize + sf.file_file_size
        end
      end

      @message.fakemessagefiles.each do |sf|
        if params["prevfakefile#{sf.id}".to_sym].nil?
          sf.destroy
        end
      end

      attach = Array.new

      i = 1
      k = 1
      while !params["hidden#{k}".to_sym].nil? do
        if !params["file#{k}".to_sym].nil?
          attach.push()
          attach[i-1] = Messagefile.new(:file => params["file#{k}".to_sym])
          attach[i-1].message = @message
          if !attach[i-1].save
            j = 1
            while j < i do
              attach[j-1].file.destroy
              attach[j-1].destroy
              j = j+1
            end
            @message.reload
            nom = params["file#{k}".to_sym].original_filename
            flash.now[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
            render 'edit' and return
          end
          totalsize = totalsize + attach[i-1].file_file_size

          i = i+1
        end
        k = k+1
      end

      if totalsize > 5242880
        j = 1
        while j < i do
          attach[j-1].file.destroy
          attach[j-1].destroy
          j = j+1
        end
        @message.reload
        flash.now[:danger] = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/524288.0).round(3)} Mo)."
        render 'edit' and return
      end

      flash[:success] = "Votre message a bien été modifié."
      tot = @message.subject.messages.where("id <= ?", @message.id).count
      page = [0,((tot-1)/10).floor].max + 1

      redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page, :q => q)

    # Si il y a eu un bug
    else
      render 'edit'
    end
  end

  # Supprimer un message : il faut être admin
  def destroy
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    @message = Message.find(params[:id])
    @subject = @message.subject

    @message.messagefiles.each do |f|
      f.file.destroy
      f.destroy
    end

    @message.destroy
    if @subject.messages.size > 0
      last = @subject.messages.order("id").last
      @subject.lastcomment = last.created_at
      @subject.save
    else
      @subject.lastcomment = @subject.created_at
      @subject.save
    end

    redirect_to subject_path(@subject, :q => q)
  end

  ########## PARTIE PRIVEE ##########
  private

  # Il faut que le chapitre existe
  def valid_chapter
    chapter_id = params[:chapter_id]
    if chapter_id.nil?
      @chapter = nil
    else
      @chapter = Chapter.find_by_id(chapter_id)
      redirect_to root_path if @chapter.nil?
    end
  end

  # Il faut que le chapitre soit en ligne ou qu'on soit admin
  def online_chapter
    if @chapter.nil?
      return
    end
    redirect_to sections_path unless (current_user.sk.admin? || @chapter.online)
  end

  # Il faut être admin si le sujet est pour admin
  def admin_subject_user
    @subject = Subject.find(params[:subject_id])
    redirect_to root_path unless (current_user.sk.admin? || !@subject.admin)
  end

  # Il faut être l'auteur ou admin pour modifier un message
  def author
    @message = Message.find(params[:id])
    redirect_to subjects_path unless (current_user.sk == @message.user || (current_user.sk.admin && !@message.user.admin) || current_user.sk.root)
  end
end
