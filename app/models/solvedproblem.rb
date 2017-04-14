#encoding: utf-8
# == Schema Information
#
# Table name: solvedproblems
#
#  id             :integer          not null, primary key
#  problem_id     :integer
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resolutiontime :datetime   (Heure d'acceptation)
#  truetime       :datetime   (Heure de résolution : dernier commentaire avant l'acceptation)
#

class Solvedproblem < ActiveRecord::Base
  # attr_accessible :resolutiontime, :truetime

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  belongs_to :submission

  # VALIDATIONS

  validates :user_id, presence: true
  validates :problem_id, presence: true, uniqueness: { scope: :user_id }
end
