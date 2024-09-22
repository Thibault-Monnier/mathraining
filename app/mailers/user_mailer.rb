#encoding: utf-8
class UserMailer < AsyncMailer

  include Resque::Mailer

  def registration_confirmation(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Confirmation d'inscription", from: "no-reply@mathraining.be")
  end

  def forgot_password(userid)
    @user = User.find(userid)
    mail(to: @user.email, subject: "Mathraining - Mot de passe oublié", from: "no-reply@mathraining.be")
  end

  def new_followed_message(userid, subjectid, authorid)
    @user = User.find(userid)
    @subject = Subject.find(subjectid)
    if authorid < 0
      @debut = "Un message automatique a été posté"
    else
      @debut = User.find(authorid).name + " a posté un message"
    end
    @page = @subject.last_page
    mail(to: @user.email, subject: "Mathraining - Nouveau message sur le sujet '" + @subject.title + "'", from: "no-reply@mathraining.be")
  end

  def new_followed_tchatmessage(userid, authorid, id)
    @user = User.find(userid)
    @qui = User.find(authorid).name
    @id = id
    mail(to: @user.email, subject: "Mathraining - Nouveau message de " + @qui, from: "no-reply@mathraining.be")
  end

  def new_message_group(userid, subjectid, authorid)
    @user = User.find(userid)
    @subject = Subject.find(subjectid)
    @qui = User.find(authorid).name
    @page = @subject.last_page
    mail(to: @user.email, subject: "Mathraining - Message à l'attention des élèves de Wépion", from: "no-reply@mathraining.be")
  end
  
  def new_followed_contestproblem(userid, contestproblemsids)
    @user = User.find(userid)
    if contestproblemsids.size == 1
      @plural = false
      @debut = "Problème ##{Contestproblem.find(contestproblemsids[0]).number}"
    else
      @plural = true
      @debut = "Problèmes"
      i = 0
      contestproblemsids.each do |id|
        if (i == contestproblemsids.size-1)
          @debut = @debut + " et"
        elsif (i > 0)
          @debut = @debut + ","
        end
        @debut = @debut + " ##{Contestproblem.find(id).number}"
        i = i+1
      end
    end
    @contestproblem = Contestproblem.find(contestproblemsids[0])
    @contest = @contestproblem.contest
    mail(to: @user.email, subject: "Mathraining - Concours #" + @contest.number.to_s + " - " + @debut, from: "no-reply@mathraining.be")
  end

end
