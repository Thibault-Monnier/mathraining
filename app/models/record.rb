#encoding: utf-8
# == Schema Information
#
# Table name: records
#

class Record < ActiveRecord::Base
  def self.update
    ajd = DateTime.now.to_date
    lastdimanche = ajd-1
    lastdimanche = lastdimanche - lastdimanche.wday
    lundidernier = lastdimanche-6
    lastrecord = Record.order(:date).last
    if(lastrecord.nil?)
      lastdate = Date.parse('1-12-2014')
    else
      lastdate = lastrecord.date
    end
    lundiencours = lastdate+7
    while(lundiencours <= lundidernier)
      lundiapres = lundiencours+7
      r = Record.new
      r.date = lundiencours
      r.number_submission = Submission.where("status != -1 AND created_at >= ? AND created_at < ?", lundiencours.to_time.to_datetime, lundiapres.to_time.to_datetime).count
      r.number_solved = Solvedexercise.where("correct = ? AND resolutiontime >= ? AND resolutiontime < ?", true, lundiencours.to_time.to_datetime, lundiapres.to_time.to_datetime).count + Solvedqcm.where("correct = ? AND resolutiontime >= ? AND resolutiontime < ?", true, lundiencours.to_time.to_datetime, lundiapres.to_time.to_datetime).count
      r.complete = false
      r.save
      lundiencours = lundiapres
    end
    
    Record.where(:complete => false).each do |r|
      lundiencours = r.date
      lundiapres = lundiencours+7
      allsolved = true
      total = 0
      number = 0
      Submission.where("created_at >= ? AND created_at < ? AND status != -1", lundiencours.to_time.to_datetime, lundiapres.to_time.to_datetime).each do |s|
        if(s.status == 0)
          allsolved = false
          break
        else
          submission_date = s.created_at
          first_correction_date = s.corrections.where("user_id != ?", s.user_id).order(:created_at).first.created_at
          total = total + (first_correction_date - submission_date)/(60*60*24).to_f
          number = number+1
        end
      end
      if allsolved
        if number > 0
          r.correction_time = total/number.to_f
        else
          r.correction_time = 0
        end
        r.complete = true
        r.save
      end
    end
  end
  
  def self.exo_guesses
    Exercise.where(:online => true).each do |e|
      nb_tries = 0
      nb_firstguess = 0
      e.solvedexercises.each do |s|
        nb_tries = nb_tries+1
        if(s.correct and s.nb_guess == 1)
          nb_firstguess = nb_firstguess+1
        end
      end
      e.nb_tries = nb_tries
      e.nb_firstguess = nb_firstguess
      e.save
    end
    
    Qcm.where(:online => true).each do |q|
      nb_tries = 0
      nb_firstguess = 0
      q.solvedqcms.each do |s|
        nb_tries = nb_tries+1
        if(s.correct and s.nb_guess == 1)
          nb_firstguess = nb_firstguess+1
        end
      end
      q.nb_tries = nb_tries
      q.nb_firstguess = nb_firstguess
      q.save
    end
  end
end
