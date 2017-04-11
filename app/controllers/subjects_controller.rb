#encoding: utf-8
class SubjectsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_subject_user, only: [:show]
  before_filter :author, only: [:edit, :update, :destroy]
  before_filter :admin_user, only: [:destroy, :migrate]
  before_filter :notskin_user, only: [:create, :update]

  # Voir tous les sujets
  def index
  	cherche_category = -1
    cherche_section = -1
    cherche_chapitre = -1
    cherche_personne = false
    q = -1
		
		@category = nil
    @chapitre = nil
    @section = nil
    if(params.has_key?:q)
      q = params[:q].to_i
      if q > 999999
      	cherche_category = q/1000000
      	@category = Category.find(cherche_category)
      elsif q > 999
        cherche_section = q/1000
        @section = Section.find(cherche_section)
      elsif q > 0
        cherche_chapitre = q
        @chapitre = Chapter.find(cherche_chapitre)
        @section = @chapitre.section
      else
        cherche_personne = true
      end
    else
      cherche_personne = true
      q = 0
    end

    @importants = Array.new
    Subject.includes(:user, :category, :section, :chapter).where(important: true).order("lastcomment DESC").to_a.each do |s|
      if ((signed_in? && current_user.sk.admin?) || !s.admin) && (!s.wepion || (signed_in? && (current_user.sk.admin? || current_user.sk.wepion)))
        if cherche_personne || (cherche_category >= 0 && !s.category.nil? && s.category.id == cherche_category) || (cherche_section >= 0 && !s.section.nil? && s.section.id == cherche_section) || (cherche_chapitre >= 0 && !s.chapter.nil? && s.chapter.id == cherche_chapitre)
          @importants.push(s)
        end
      end
    end

    @subjects = Array.new
    Subject.includes(:user, :category, :section, :chapter).where(important: false).order("lastcomment DESC").to_a.each do |s|
      if (signed_in? && current_user.sk.admin?) || !s.admin && (!s.wepion || (signed_in? && (current_user.sk.admin? || current_user.sk.wepion)))
        if cherche_personne || (cherche_category >= 0 && !s.category.nil? && s.category.id == cherche_category) || (cherche_section >= 0 && !s.section.nil? && s.section.id == cherche_section) || (cherche_chapitre >= 0 && !s.chapter.nil? && s.chapter.id == cherche_chapitre)
          @subjects.push(s)
        end
      end
    end

    @subjectsfalse = @subjects.paginate(:page => params[:page], :per_page => 15)
  end

  # Montre un sujet
  def show
    @messages = @subject.messages.order(:id).paginate(:page => params[:page], :per_page => 10)
  end

  # Créer un sujet
  def new
    @subject = Subject.new
    if @section.nil?
      @preselect = 0
    elsif @chapter.nil?
      @preselect = 1000*@section
    else
      @preselect = @chapter
    end
  end

  # Editer un sujet
  def edit
    if @subject.section.nil?
      @preselect = 0
    elsif @subject.chapter.nil?
      @preselect = 1000*@subject.section.id
    else
      @preselect = @subject.chapter.id
    end
  end

  # Créer un sujet 2
  def create
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    if !current_user.sk.admin? && !params[:subject][:important].nil? # Hack
      redirect_to root_path and return
    end

    @subject = Subject.new(params[:subject].except(:chapter_id, :category_id, :exercise_id))
    @subject.user = current_user.sk
    @subject.lastcomment = DateTime.current

    if @subject.admin
      @subject.wepion = false # On n'autorise pas wépion si admin
    end
    
    if @subject.title.size > 0
      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)
    end
    
    category_id = params[:subject][:category_id].to_i
    if category_id < 1000
    	@subject.category = Category.find(category_id)
    	@subject.section = nil
    	@subject.chapter = nil
    	@subject.exercise = nil
    	@subject.qcm = nil
    else
    	section_id = category_id/1000
    	@subject.category = nil
    	@subject.section = Section.find(section_id)
    	chapter_id = params[:subject][:chapter_id].to_i
    	if chapter_id == 0
    		@subject.chapter = nil
    		@subject.exercise = nil
    		@subject.qcm = nil
    	else
    		@subject.chapter = Chapter.find(chapter_id)
    		exercise_id = params[:subject][:exercise_id].to_i
    		if exercise_id == 0
    			@subject.exercise = nil
    			@subject.qcm = nil
    		else
    			type = exercise_id / 1000
    			exercise_id = exercise_id % 1000
    			if type == 2
    				@subject.exercise = Exercise.find(exercise_id)
    				@subject.qcm = nil
    			else
    				@subject.qcm = Qcm.find(exercise_id)
    				@subject.exercise = nil
    			end
    		end
    	end
    end

    # Gérer les pièces jointes
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Subjectfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          flash.now[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          @preselect = params[:subject][:chapter_id].to_i
          render 'new' and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end

      flash.now[:danger] = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)."
      @preselect = params[:subject][:chapter_id].to_i
      render 'new' and return
    end

    # Si on parvient à enregistrer
    if @subject.save
      j = 1
      while j < i do
        attach[j-1].subject = @subject
        attach[j-1].save
        j = j+1
      end
      if !current_user.sk.admin? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end
      
      if current_user.sk.admin?
		    if params.has_key?(:groupeA)
		    	User.where(:group => "A").each do |u|
		    		UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, 0).deliver
		    	end
		    end
		    if params.has_key?(:groupeB)
		    	User.where(:group => "B").each do |u|
		    		UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, 0).deliver
		    	end
		    end
		  end
      
      flash[:success] = "Votre sujet a bien été posté."

      redirect_to subject_path(@subject, :q => q)

    # Si il y a eu une erreur
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      @preselect = params[:subject][:chapter_id].to_i
      render 'new'
    end
  end

  # Modifier un sujet
  def update
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    if !current_user.sk.admin? && !params[:subject][:important].nil? # Hack
      redirect_to root_path
    end

    if @subject.update_attributes(params[:subject].except(:chapter_id, :category_id, :exercise_id))

      if @subject.admin
        @subject.wepion = false # On n'autorise pas wépion si admin
        @subject.save
      end

      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)

      category_id = params[:subject][:category_id].to_i
		  if category_id < 1000
		  	@subject.category = Category.find(category_id)
		  	@subject.section = nil
		  	@subject.chapter = nil
		  	@subject.exercise = nil
		  	@subject.qcm = nil
		  else
		  	section_id = category_id/1000
		  	@subject.category = nil
		  	@subject.section = Section.find(section_id)
		  	chapter_id = params[:subject][:chapter_id].to_i
		  	if chapter_id == 0
		  		@subject.chapter = nil
		  		@subject.exercise = nil
		  		@subject.qcm = nil
		  	else
		  		@subject.chapter = Chapter.find(chapter_id)
		  		exercise_id = params[:subject][:exercise_id].to_i
		  		if exercise_id == 0
		  			@subject.exercise = nil
		  			@subject.qcm = nil
		  		else
		  			type = exercise_id / 1000
		  			exercise_id = exercise_id % 1000
		  			if type == 2
		  				@subject.exercise = Exercise.find(exercise_id)
		  				@subject.qcm = nil
		  			else
		  				@subject.qcm = Qcm.find(exercise_id)
		  				@subject.exercise = nil
		  			end
		  		end
		  	end
		  end
		  
		  @subject.save

      if !current_user.sk.admin? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end

      totalsize = 0

      @subject.subjectfiles.each do |sf|
        if params["prevfile#{sf.id}".to_sym].nil?
          sf.file.destroy
          sf.destroy
        else
          totalsize = totalsize + sf.file_file_size
        end
      end

      @subject.fakesubjectfiles.each do |sf|
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
          attach[i-1] = Subjectfile.new(:file => params["file#{k}".to_sym])
          attach[i-1].subject = @subject
          if !attach[i-1].save
            j = 1
            while j < i do
              attach[j-1].file.destroy
              attach[j-1].destroy
              j = j+1
            end
            nom = params["file#{k}".to_sym].original_filename
            @subject.reload
            flash.now[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
            @preselect = params[:subject][:chapter_id].to_i
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
        @subject.reload
        flash.now[:danger] = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/524288.0).round(3)} Mo)"
        @preselect = params[:subject][:chapter_id].to_i
        render 'edit' and return
      end

      flash[:success] = "Votre sujet a bien été modifié."

      redirect_to subject_path(@subject, :q => q)
    else
      @preselect = params[:subject][:chapter_id].to_i
      render 'edit'
    end
  end

  # Supprimer un sujet : il faut être admin
  def destroy
    q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end

    @subject.delete
    @subject.subjectfiles.each do |f|
      f.file.destroy
      f.destroy
    end
    @subject.messages.each do |m|
      m.messagefiles.each do |f|
        f.file.destroy
        f.destroy
      end
      m.destroy
    end
    @subject.followingsubjects.each do |f|
      f.destroy
    end
    flash[:success] = "Sujet supprimé."

    redirect_to subjects_path(:q => q)
  end
  
  # Migrer un sujet vers un autre : il faut être root (disons admin)
  def migrate
  	q = 0
    if(params.has_key?:q)
      q = params[:q].to_i
    end
    
  	@subject = Subject.find(params[:subject_id])
  	autre_id = params[:migreur].to_i
  	@migreur = Subject.find(autre_id)
  	
  	premier_message = Message.new(content: @subject.content + "\n\n[i][u]Remarque[/u] : Ce message faisait partie d'un autre sujet appelé '#{@subject.title}' et a été migré ici par un administrateur.[/i]", created_at: @subject.created_at)
  	premier_message.user = @subject.user
  	premier_message.subject = @migreur
  	premier_message.save
  	
  	@subject.messages.order(:id).each do |m|
  		newm = Message.new(content: m.content, created_at: m.created_at)
  		newm.user = m.user
  		newm.subject = @migreur
  		newm.save
  		m.delete
  	end
  	
  	@migreur.lastcomment = [@migreur.lastcomment, @subject.lastcomment].max
  	@migreur.save
  	
  	@subject.delete
  	
  	redirect_to subject_path(@migreur, :q => q)
  end

  ########## PARTIE PRIVEE ##########
  private

  def admin_subject_user
    @subject = Subject.find(params[:id])
    redirect_to root_path unless ((signed_in? && current_user.sk.admin?) || !@subject.admin)
  end

  def author
    @subject = Subject.find(params[:id])
    redirect_to subjects_path unless (current_user.sk == @subject.user || (current_user.sk.admin && !@subject.user.admin) || current_user.sk.root)
  end
end
