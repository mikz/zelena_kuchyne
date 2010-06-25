class CreateTotalScheduledMealsView < ActiveRecord::Migration
  def self.up
    sql_script 'total_scheduled_meals_view_up'
  end

  def self.down
    sql_script 'total_scheduled_meals_view_down'
  end
end
