class CreateRestaurantSales < ActiveRecord::Migration
  def self.up
    sql_script 'restaurant_sales_up'
    sql_script 'ingredients_log_from_restaurant_up'
  end

  def self.down
    sql_script 'ingredients_log_from_restaurant_down'
    sql_script 'restaurant_sales_down'
  end
end
