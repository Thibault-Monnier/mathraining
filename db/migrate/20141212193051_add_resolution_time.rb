class AddResolutionTime < ActiveRecord::Migration
  def change
    add_column :solvedexercises, :resolutiontime, :datetime
    add_column :solvedproblems, :resolutiontime, :datetime
    add_column :solvedqcms, :resolutiontime, :datetime
  end
end
