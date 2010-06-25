require File.dirname(__FILE__) + '/../test_helper'
require "bigdecimal"

class MealComputedTest < ActiveSupport::TestCase
  fixtures :users, :meals, :bundles
  ### actual tests
  
  def test_cost
    tested_meals = []
    tested_meals << meals(:pecene_brambory)
    tested_meals << meals(:smetanova_polevka)
    tested_meals << meals(:fazolovy_salat)
    tested_meals << meals(:gulas)
    tested_meals << meals(:zelnacka)
    tested_meals << meals(:mrkvovy_salat)
    tested_meals << meals(:paprikovy_salat)
    
    for meal in tested_meals
      meal_computed = MealComputed.find meal.id
      cost = BigDecimal.new("0")
      for recipe in meal.recipes
        cost += BigDecimal.new(recipe.ingredient.cost.to_s) * BigDecimal.new(recipe.amount.to_s)
      end
      assert_equal cost, BigDecimal.new(meal_computed.cost.to_s)
    end
  end
  
  def test_cost_and_amount_updates
    tested_meals = []
    tested_meals << meals(:pecene_brambory)
    tested_meals << meals(:smetanova_polevka)
    tested_meals << meals(:fazolovy_salat)
    tested_meals << meals(:gulas)
    tested_meals << meals(:zelnacka)
    tested_meals << meals(:mrkvovy_salat)
    tested_meals << meals(:paprikovy_salat)
    
    for meal in tested_meals
      ingredient = meal.ingredients.first
      meal_computed = MealComputed.find meal.id
      
      ingredient.cost += 0.1
      ingredient.save
      
      cost = BigDecimal.new("0")
      for recipe in meal.recipes
        recipe.amount += 50 if recipe.ingredient.id == meal.ingredients.last
        cost += BigDecimal.new(recipe.amount.to_s) * BigDecimal.new(recipe.ingredient.cost.to_s)
        recipe.save if recipe.changed
      end
      
      assert_equal cost, BigDecimal.new(meal_computed.reload.cost.to_s)
      
    end
  end
  
end
