# -*- encoding : utf-8 -*-
class MealComputed < Meal
  set_primary_key 'id'
  set_table_name 'meals_view'
  has_many :courses, :foreign_key => "meal_id"
  has_many :menus, :foreign_key => "meal_id", :class_name => "MenuComputed", :through => :courses
  
  def save
    meal = self.becomes(Meal)
    self.changed.each { |attr|
      meal.send "#{attr}_will_change!"
    }
    meal.save
    self.reload
  end

  def update_attributes attrs
    self.becomes(Meal).update_attributes attrs
    save
  end

  def cost
    self[:cost]
  end
end

