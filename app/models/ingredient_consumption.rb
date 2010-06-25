class IngredientConsumption < ActiveRecord::Base
  has_many :stocktakings
  has_one :log, :class_name => "IngredientsLogFromStocktaking", :through => :stocktakings, :conditions => 'ingredient_id = #{ingredient_id}'
  has_one :ingredient, :through => :log, :conditions => 'ingredient_id = #{ingredient_id}'
end