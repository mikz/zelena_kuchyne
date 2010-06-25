class CreateIngredients < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_up'
    sql_script 'ingredients_functions_up'
  end

  def self.down
    sql_script 'ingredients_functions_down'
    sql_script 'ingredients_down'
  end
end
