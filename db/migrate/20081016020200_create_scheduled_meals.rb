class CreateScheduledMeals < ActiveRecord::Migration
  def self.up
    sql_script 'scheduled_meals_up'
    sql_script 'scheduled_meals_functions_up'
  end

  def self.down
    sql_script 'scheduled_meals_functions_down'
    sql_script 'scheduled_meals_down'
  end
end
