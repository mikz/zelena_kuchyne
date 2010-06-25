class CreateMealsView < ActiveRecord::Migration
  def self.up
    sql_script 'meals_view_up'
  end

  def self.down
    sql_script 'meals_view_down'
  end
end
