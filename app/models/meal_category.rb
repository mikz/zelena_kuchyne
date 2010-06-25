class MealCategory < ActiveRecord::Base
  has_many :meals, :order => "meals.name ASC"
  has_many :bundles, :through => :meals
end
