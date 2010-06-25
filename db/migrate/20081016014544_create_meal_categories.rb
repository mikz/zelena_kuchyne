class CreateMealCategories < ActiveRecord::Migration
  def self.up
    sql_script 'meal_categories_up'
  end

  def self.down
    sql_script 'meal_categories_down'
  end
end
