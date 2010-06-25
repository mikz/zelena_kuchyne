class CreateMealFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'meal_functions_up'
  end

  def self.down
    sql_script 'meal_functions_down'
  end
end
