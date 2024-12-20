#encoding: utf-8

# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string
#  color        :string
#  femininename :string
#
class Color < ActiveRecord::Base

  # VALIDATIONS

  validates :pt, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :femininename, presence: true, length: { maximum: 255 }
  validates :color, presence: true, length: { is: 7 }
  
  # DEFAULTS
  
  def self.create_defaults
    Color.create(pt: 0,    name: "Novice",       color: "#888888", femininename: "Novice")
    Color.create(pt: 70,   name: "Débutant",     color: "#08D508", femininename: "Débutante")
    Color.create(pt: 200,  name: "Initié",       color: "#008800", femininename: "Initiée")
    Color.create(pt: 400,  name: "Compétent",    color: "#00BBEE", femininename: "Compétente")
    Color.create(pt: 750,  name: "Qualifié",     color: "#0033FF", femininename: "Qualifiée")
    Color.create(pt: 1250, name: "Expérimenté",  color: "#DD77FF", femininename: "Expérimentée")
    Color.create(pt: 2000, name: "Chevronné",    color: "#A000A0", femininename: "Chevronnée")
    Color.create(pt: 3200, name: "Expert",       color: "#FFA000", femininename: "Experte")
    Color.create(pt: 5000, name: "Maître",       color: "#FF4400", femininename: "Maître")
    Color.create(pt: 7500, name: "Grand Maître", color: "#CC0000", femininename: "Grand Maître")
  end
end
