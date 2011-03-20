class MealCategory < ActiveRecord::Base
  has_many :meals, :order => "meals.name ASC"
  has_many :bundles, :through => :meals
  has_one  :order, :class_name => "MealCategoryOrder", :foreign_key => "category_id", :dependent => :destroy
  
  after_create :create_order
  
end
