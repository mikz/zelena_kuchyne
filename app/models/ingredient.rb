class Ingredient < ActiveRecord::Base
  has_many :meals, :through => :recipes, :order => "meals.name ASC"
  has_many :recipes
  belongs_to :supplier
  named_scope :by_name, :order => "ingredients.name ASC"
end
