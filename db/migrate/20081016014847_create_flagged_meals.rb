class CreateFlaggedMeals < ActiveRecord::Migration
  def self.up
    sql_script 'flagged_meals_up'
  end

  def self.down
    sql_script 'flagged_meals_down'
  end
end
