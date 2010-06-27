class CreateMealCategoryOrders < ActiveRecord::Migration
  def self.up
    sql_script 'meal_category_order_up'
    i = 0
    MealCategory.all.each do |c|
      MealCategoryOrder.create :category => c, :order => i
      i += 1
    end
  end

  def self.down
    sql_script 'meal_category_order_down'
  end
end
