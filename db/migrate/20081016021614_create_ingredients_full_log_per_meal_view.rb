class CreateIngredientsFullLogPerMealView < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_full_log_per_meal_view_up'
  end

  def self.down
    sql_script 'ingredients_full_log_per_meal_view_down'
  end
end
