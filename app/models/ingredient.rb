class Ingredient < ActiveRecord::Base
  has_many :meals, :through => :recipes, :order => "meals.name ASC"
  has_many :recipes
  belongs_to :supplier
end
