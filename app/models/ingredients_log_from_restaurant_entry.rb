class IngredientsLogFromRestaurantEntry < ActiveRecord::Base
  set_table_name 'ingredients_log_from_restaurant'
  set_primary_key 'id'
  belongs_to :ingredient
  belongs_to :meal
  belongs_to :restaurant_sale
  
  def self.create_for_meal(restaurant_sale, meal)
    self.connection.execute create_sql_for_meal(restaurant_sale, meal)
  end
  
  def self.create_for_meals(restaurant_sale, meals)
    sql = ""
    meals.each do |meal|
      sql << create_sql_for_meal(restaurant_sale, meal)
    end
    self.connection.execute sql
  end
  
  def self.update_for_meal(restaurant_sale, meal)
    self.connection.execute update_sql_for_meal(restaurant_sale, meal)
  end
  
  def self.update_for_meals(restaurant_sale, meals)
    sql = ""
    meals.each do |meal|
      sql << update_sql_for_meal(restaurant_sale, meal)
    end
    self.connection.execute sql
  end
  
  
  protected
  def self.create_sql_for_meal(restaurant_sale, meal)
    sql = ""
    meal.recipes.each do |recipe|
      sql << "INSERT INTO #{table_name}(day, amount, ingredient_id, ingredient_price, meal_id, restaurant_sale_id) VALUES('#{Date.parse(restaurant_sale.sold_at.to_s)}', -#{recipe.amount}*#{restaurant_sale.amount}, #{recipe.ingredient_id}, ingredient_cost(#{recipe.ingredient_id}), #{meal.id}, #{restaurant_sale.id});\n"
    end
    sql
  end
  
  def self.update_sql_for_meal(restaurant_sale, meal)
    sql = ""
    meal.recipes.each do |recipe|
      sql << "UPDATE #{table_name} SET amount = (-#{recipe.amount} * #{restaurant_sale.amount}), day = '#{Date.parse(restaurant_sale.sold_at.to_s)}' WHERE meal_id = #{meal.id} AND restaurant_sale_id = #{restaurant_sale.id} AND ingredient_id = #{recipe.ingredient_id};\n"
    end
    sql
  end
end