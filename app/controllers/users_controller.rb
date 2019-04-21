#encoding: utf-8
class UsersController < ApplicationController
  before_action :signed_in_user, only: [:edit, :allsub, :allmysub, :notifs_show, :groups, :read_legal]
  before_action :signed_in_user_danger, only: [:destroy, :destroydata, :update, :create_administrator, :take_skin, :leave_skin, :unactivate, :reactivate, :switch_wepion, :switch_corrector, :change_group]
  before_action :get_user, only: [:edit, :update, :show, :destroy, :activate]
  before_action :get_user2, only: [:destroydata, :change_password, :take_skin, :create_administrator, :switch_wepion, :switch_corrector, :change_group, :recup_password]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:take_skin, :unactivate, :reactivate, :switch_wepion, :change_group]
  before_action :corrector_user, only: [:allsub, :allmysub]
  before_action :root_user, only: [:create_administrator, :destroy, :destroydata, :switch_corrector, :validate_name]
  before_action :signed_out_user, only: [:new, :create, :password_forgotten]
  before_action :group_user, only: [:groups]

  # Index de tous les users avec scores
  def index
    @pays = 0
    if(params.has_key?:country)
      @pays = params[:country].to_i
    end
    
    @rank = 1
    if(params.has_key?:rank)
      @rank = params[:rank].to_i
    end
    
    @allsec = Section.order(:id).where(:fondation => false).to_a

    @previouspoint = -1

    if User.last.nil?
      @recent = Array.new(1)
      @persection = Array.new(1)
    else
      @recent = Array.new(User.last.id+1)
      @persection = Array.new(User.last.id+1)
    end
    twoweeksago = Date.today - 14

    @maxscore = Array.new

    Section.all.each do |s|
      @maxscore[s.id] = s.max_score
    end
    
    # Number of people to load on each "page"
    nb_load = 100

    @ordered_users = Array.new
    # If first page: first download the best students in random order
    if !params.has_key?(:from)
      r = Random.new(Date.today.in_time_zone.to_time.to_i)
      max_rating = -1
      if @pays == 0
        max_user = User.where("admin = ? AND active = ?", false, true).order("rating DESC").first
      else
        max_user = User.where("admin = ? AND active = ? AND country_id = ?", false, true, @pays).order("rating DESC").first
      end

      if !max_user.nil?
        max_rating = max_user.rating
      end

      if @pays == 0
        mylist = User.where("rating = ? AND admin = ? AND active = ?", max_rating, false, true).order(:id)
      else
        mylist = User.where("rating = ? AND admin = ? AND active = ? AND country_id = ?", max_rating, false, true, @pays).order(:id)
      end
      
      encours = Array.new
      mylist.each do |user|
        alea = r.rand()
        alea = 0 if @signed_in && current_user.sk == user
        encours.push([alea, user])
      end

      encours.sort!
      encours.each do |u|
        @ordered_users.push(u[1])
      end
      nb_load = [nb_load - encours.size, 0].max
      from = max_rating - 1
    else
      from = params[:from].to_i
    end
    
    # Get following users    
    if @pays == 0
      prov = User.where("rating != 0 AND rating <= ? AND admin = ? AND active = ?", from, false, true).order("rating DESC, last_name ASC, first_name ASC").limit(nb_load).last
    else
      prov = User.where("rating != 0 AND rating <= ? AND admin = ? AND active = ? AND country_id = ?", from, false, true, @pays).order("rating DESC, last_name ASC, first_name ASC").limit(nb_load).last
    end
    
    if !prov.nil?
      to = prov.rating
    else
      to = 1
    end
    
    if @pays == 0
      arr = User.where("rating <= ? AND rating >= ? AND admin = ? AND active = ?", from, to, false, true).order("rating DESC, last_name ASC, first_name ASC").to_a
    else
      arr = User.where("rating <= ? AND rating >= ? AND admin = ? AND active = ? AND country_id = ?", from, to, false, true, @pays).order("rating DESC, last_name ASC, first_name ASC").to_a
    end
    
    @ordered_users.push(*arr)
    
    ids = Array.new
    
    @ordered_users.each do |u|
      ids.push(u.id)
      @recent[u.id] = 0
      @persection[u.id] = Array.new
    end

    Solvedproblem.where(:user_id => ids).includes(:problem).where("truetime > ?", twoweeksago).find_each do |s|
      @recent[s.user_id] += s.problem.value
    end

    Solvedquestion.where(:user_id => ids).includes(:question).where("resolutiontime > ?", twoweeksago).find_each do |s|
      if s.correct
        exo = s.question
        @recent[s.user_id] += exo.value
      end
    end

    Pointspersection.where(:user_id => ids).all.each do |p|
	    @persection[p.user_id][p.section_id] = p.points
    end
  end

  # S'inscrire au site : il faut être en ligne
  def new
    @user = User.new
  end

  # Modifier son compte : il faut être en ligne et que ce soit la bonne personne
  def edit
  end

  # S'inscrire au site 2 : il faut être hors ligne
  def create
    @user = User.new(params.require(:user).permit(:first_name, :last_name, :seename, :email, :email_confirmation, :sex, :year, :password, :password_confirmation, :accept_analytics))
    @user.key = SecureRandom.urlsafe_base64
    
    if(!params[:user][:country].nil? && params[:user][:country].to_i > 0)
      c = Country.find(params[:user][:country])
      @user.country = c
    end

    # Don't do e-mail and captcha in development and tests
    @user.email_confirm = !Rails.env.production?
    
    # Remove white spaces at start and end, and add '.' if needed
    @user.adapt_name
    
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir créer un compte."
      render 'new'
    elsif (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.save
      UserMailer.registration_confirmation(@user.id).deliver if Rails.env.production?
      
      @user.consent_date = DateTime.now
      @user.last_policy_read = true
      @user.save
      
      flash[:success] = "Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver. Vous avez 7 jours pour confirmer votre inscription. Si vous rencontrez un problème, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Voir un utilisateur
  def show
  end

  def compare
    @user = []
    @user[1] = User.find_by_id(params[:id1])
    @user[2] = User.find_by_id(params[:id2])
    if @user[1].nil? || !@user[1].active || @user[2].nil? || !@user[2].active
      render 'errors/access_refused' and return
    end
  end

  # Modifier son compte 2 : il faut être en ligne et que ce soit la bonne personne
  def update
    old_last_name = @user.last_name
    old_first_name = @user.first_name

    if @user.update_attributes(params.require(:user).permit(:first_name, :last_name, :seename, :sex, :year, :password, :password_confirmation, :email, :accept_analytics))
      c = Country.find(params[:user][:country])
      @user.update_attribute(:country, c)
      @user.adapt_name
      @user.save
      flash[:success] = "Votre profil a bien été mis à jour."
      if(current_user.root? and current_user.other)
        @user.update_attribute(:valid_name, true)
        current_user.update_attribute(:skin, 0)
        redirect_to validate_name_path
      elsif((old_last_name != @user.last_name || old_first_name != @user.first_name) && !current_user.sk.admin)
        @user.update_attribute(:valid_name, false)
        redirect_to root_path
      else
        redirect_to root_path
      end
    else
      render 'edit'
    end
  end

  # Supprimer un utilisateur : il faut être root
  def destroy
    if !@user.root?
      skinner = User.where(skin: @user.id)
      skinner.each do |s|
        s.update_attribute(:skin, 0)
      end
      @user.destroy
      flash[:success] = "Utilisateur supprimé."
    else
      flash[:danger] = "Il n'est pas possible de supprimer un root."
    end
    redirect_to @user
  end

  # Rendre administrateur : il faut être root
  def create_administrator
    if @user.admin?
      flash[:danger] = "I see what you did here! Mais non ;-)"
    else
      @user.toggle!(:admin)
      skinner = User.where(skin: @user.id)
      skinner.each do |s|
        s.update_attribute(:skin, 0)
      end
      flash[:success] = "Utilisateur promu au rang d'administrateur !"
    end
    redirect_to @user
  end

  # Ajouter / Enlever du groupe Wépion
  def switch_wepion
    if !@user.admin?
      if @user.wepion
        flash[:success] = "Utilisateur retiré du groupe Wépion."
        @user.group = ""
        @user.save
      else
        flash[:success] = "Utilisateur ajouté au groupe Wépion."
      end
      @user.toggle!(:wepion)
    end
    redirect_to @user
  end

  # Ajouter / Enlever des correcteurs
  def switch_corrector
    if !@user.admin?
      if !@user.corrector
        flash[:success] = "Utilisateur ajouté aux correcteurs."
      else
        flash[:success] = "Utilisateur retiré des correcteurs."
      end
      @user.toggle!(:corrector)
    end
    redirect_to @user
  end

  # Changer de groupe
  def change_group
    g = params[:group]
    @user.group = g
    @user.save
    flash[:success] = "Utilisateur changé de groupe."
    redirect_to @user
  end

  # Activer son compte
  def activate
    if !@user.email_confirm && @user.key.to_s == params[:key].to_s
      @user.toggle!(:email_confirm)
      flash[:success] = "Votre compte a bien été activé! Veuillez maintenant vous connecter."
    elsif @user.key.to_s != params[:key].to_s
      flash[:danger] = "Le lien d'activation est erroné."
    else
      flash[:info] = "Ce compte est déjà actif !"
    end
    redirect_to root_path
  end

  # Mot de passe oublié
  def password_forgotten
      @user = User.new
      if (Rails.env.production? and !verify_recaptcha(:model => @user, :message => "Captcha incorrect"))
        render 'forgot_password'
      else
      @user = User.where(:email => params[:user][:email]).first
      if @user
        if @user.email_confirm
          @user.update_attribute(:key, SecureRandom.urlsafe_base64)
          @user.update_attribute(:recup_password_date_limit, DateTime.now)
          UserMailer.forgot_password(@user.id).deliver if Rails.env.production?
          flash[:info] = "Lien (développement uniquement) : localhost:3000/users/#{@user.id}/recup_password?key=#{@user.key}" if Rails.env.development?
          flash[:success] = "Vous allez recevoir un e-mail d'ici quelques minutes pour que vous puissiez changer de mot de passe. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
        else
          flash[:danger] = "Veuillez d'abord confirmer votre adresse e-mail à l'aide du lien qui vous a été envoyé à l'inscription. Si vous n'avez pas reçu cet e-mail, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
        end
      else
        flash[:danger] = "Aucun utilisateur ne possède cette adresse."
      end
      redirect_to root_path
    end
  end

  # Mot de passe oublié 2
  def recup_password  
    if @user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?
      flash[:danger] = "Ce lien n'est pas valide (ou a déjà été utilisé)."
      redirect_to root_path
    elsif DateTime.now.in_time_zone > @user.recup_password_date_limit + 3600
      flash[:danger] = "Ce lien n'est plus valide (il expirait après une heure). Veuillez en redemander un autre."
      redirect_to root_path
    else
      # Si le paramètre "signed_out" n'est pas présent alors on le rajoute
      # C'est pour éviter le problème qui arrive si quelqu'un essaye de se connecter depuis cette page
      # En effet quand on se connecte on est redirigé vers la page précédente, et celle-ci déconnectait immédiatement l'utilisateur...
      if(params[:signed_out].nil?)
        if @signed_in
          sign_out
        end
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      elsif @signed_in
        # Si on a "signed_out" et qu'on est connecté, ça veut dire qu'on vient de se connecter
        redirect_to root_path
      end
    end
  end
  
  # Mot de passe oublié 3
  def change_password
    if (@user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?)
      flash[:danger] = "Une erreur est survenue. Il semble que votre lien pour changer de mot de passe ne soit plus valide."
      redirect_to root_path
    elsif DateTime.now.in_time_zone > @user.recup_password_date_limit + 3600
      flash[:danger] = "Vous avez mis trop de temps à modifier votre mot de passe. Veuillez réitérer votre demande de changement de mot de passe."
      redirect_to root_path
    else
      if (params[:user][:password].nil? or params[:user][:password].length == 0)
        session["errorChange"] = ["Mot de passe est vide"]
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      elsif (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.update_attributes(params.require(:user).permit(:password, :password_confirmation))
        @user.update_attribute(:key, SecureRandom.urlsafe_base64)
        @user.update_attribute(:recup_password_date_limit, nil)
        flash[:success] = "Votre mot de passe vient d'être modifié. Vous pouvez maintenant vous connecter à votre compte."
        redirect_to root_path
      else
        session["errorChange"] = @user.errors.full_messages
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      end
    end
  
  end

  # Voir toutes les soumissions (admin)
  def allsub
    @notifications = Submission.includes(:user, :problem, followings: :user).where(visible: true).order("lastcomment DESC").paginate(page: params[:page]).to_a
    @new = true
    render :allsub
  end

  # Voir les soumissions auxquelles on participe (admin)
  def allmysub
    @notifications = current_user.sk.followed_submissions.includes(:user, :problem).where("status > 0").order("lastcomment DESC").paginate(page: params[:page]).to_a
    @new = false
    render :allsub
  end
  
  # Voir toutes les nouvelles soumissions (admin)
  def allnewsub
    @notifications = Submission.includes(:user, :problem, followings: :user).where(status: 0, visible: true).order("created_at").to_a
    @new = true
    render :allnewsub
  end

  # Voir les nouveaux commentaires des soumissions auxquelles on participe (admin)
  def allmynewsub
    @notifications = current_user.sk.followed_submissions.includes(:user, :problem).order("lastcomment").to_a
    @notifications_other = Submission.includes(:user, :problem, followings: :user).where("status = 3").order("lastcomment").to_a
    @new = false
    render :allnewsub
  end

  # Voir les notifications (étudiant)
  def notifs_show
    @notifs = current_user.sk.notifs.order("created_at")
    render :notifs
  end

  # Prendre la peau d'un utilisateur
  def take_skin
    if @user.admin || !@user.active
      flash[:danger] = "Pas autorisé..."
    else
      current_user.update_attribute(:skin, @user.id)
      flash[:success] = "Vous êtes maintenant dans la peau de #{@user.name}."
    end
    redirect_back(fallback_location: root_path)
  end

  # Quitter la peau d'un utilisateur
  def leave_skin
    if current_user.id == params[:user_id].to_i
      current_user.update_attribute(:skin, 0)
      flash[:success] = "Vous êtes à nouveau dans votre peau."
    end
    redirect_back(fallback_location: root_path)
  end

  # Supprimer les données d'un compte
  def destroydata
    if @user.active
      flash[:success] = "Les données personnelles de #{@user.name} ont été supprimées."
      @user.active = false
      @user.email = @user.id.to_s
      @user.first_name = "Compte"
      @user.last_name = "Supprimé"
      @user.seename = 1
      @user.wepion = false
      @user.valid_name = true
      @user.follow_message = false
      @user.save
      @user.followingsubjects.each do |f|
        f.destroy
      end
    end
    redirect_to root_path
  end

  def groups
  end

  def correctors
  end
  
  def validate_name
    u = User.where(:admin => false, :valid_name => false, :email_confirm => true).first
    if(!u.nil?)
      current_user.update_attribute(:skin, u.id)
      redirect_to edit_user_path(u)
    else
      current_user.update_attribute(:skin, 0)
      flash[:success] = "Aucun nom à valider !"
      redirect_to root_path
    end
  end
  
  def read_legal
  end
  
  def accept_legal
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir continuer sur le site."
      render 'read_legal'
    else
      user = current_user
      user.consent_date = DateTime.now
      user.last_policy_read = true
      user.save
      redirect_to root_path
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  def get_user
    @user = User.find_by_id(params[:id])
    if @user.nil? || !@user.active?
      render 'errors/access_refused' and return
    end
  end
  
  def get_user2
    @user = User.find_by_id(params[:user_id])
    if @user.nil? || !@user.active?
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie qu'il s'agit de la bonne personne
  def correct_user
    if current_user.sk.id != @user.id
      render 'errors/access_refused' and return
    end
  end

  def group_user
    if !current_user.sk.admin && current_user.sk.group == ""
      render 'errors/access_refused' and return
    end
  end
  
end
