require File.dirname(__FILE__) + '/../test_helper'

class RestaurantSaleTest < ActiveSupport::TestCase
  def test_create_and_update
    sold_meal = RestaurantSale.create!(:premise => premises(:provozovna), :item_id => meals(:halusky).item_id, :sold_at => "2016-02-10", :amount => 10)
    assert_valid sold_meal
    scheduled_menu = ScheduledMenu.create!(:menu => menus(:delikatni_menu), :amount => 10 ) {|sm| sm.scheduled_for = "2016-02-10"}
    assert_valid scheduled_menu.reload
    scheduled_meal = ScheduledMeal.create!(:meal => meals(:fazolovy_salat), :amount => 10) {|sm| sm.scheduled_for = "2016-02-10"}
    assert_valid scheduled_meal.reload
    menu_log = IngredientsLogFromMenusEntry.find(:all, :conditions => ["scheduled_menu_id = ?", scheduled_menu.oid], :include => :ingredient)
    num_of_ingredients = 0
    scheduled_menu.menu.meals.each do |meal|
      meal.recipes.each { |recipe|
        menu_log.each do |log|
          if log.ingredient.id == recipe.ingredient.id && meal.id == log.meal.id
            assert_equal -recipe.amount*scheduled_menu.amount, log.amount
          end
        end
        num_of_ingredients += 1
      }
    end
    assert_equal num_of_ingredients, menu_log.size
    sold_menu = RestaurantSale.create!(:premise => premises(:provozovna), :item_id => menus(:delikatni_menu).item_id, :amount => 5, :sold_at => "2016-02-10")
    assert_valid sold_menu
    menu_log = IngredientsLogFromMenusEntry.find(:all, :conditions => ["scheduled_menu_id = ?", scheduled_menu.oid], :include => :ingredient)
    restaurant_log = IngredientsLogFromRestaurantEntry.find :all, :conditions => ["restaurant_sale_id = ?", sold_menu.id], :include => :ingredient
    assert_equal scheduled_menu.amount - sold_menu.amount, scheduled_menu.reload.amount
    num_of_ingredients = 0
    scheduled_menu.menu.meals.each do |meal|
      meal.recipes.each { |recipe|
        menu_log.each do |log|
          if log.ingredient.id == recipe.ingredient.id && meal.id == log.meal.id
            assert_equal -recipe.amount*scheduled_menu.amount, log.amount
          end
        end
        restaurant_log.each do |log|
          if log.ingredient.id == recipe.ingredient.id && meal.id == log.meal.id
            assert_equal -recipe.amount*sold_menu.amount, log.amount
          end
        end
        num_of_ingredients += 1
      }
    end
    assert_equal num_of_ingredients, menu_log.size
    sold_menu.amount += 3
    assert sold_menu.save
    assert_equal scheduled_menu.amount - 3, scheduled_menu.reload.amount
    menu_log = IngredientsLogFromMenusEntry.find(:all, :conditions => ["scheduled_menu_id = ?", scheduled_menu.oid], :include => :ingredient)
    restaurant_log = IngredientsLogFromRestaurantEntry.find :all, :conditions => ["restaurant_sale_id = ?", sold_menu.id], :include => :ingredient
    num_of_ingredients = 0
    scheduled_menu.menu.meals.each do |meal|
      meal.recipes.each { |recipe|
        menu_log.each do |log|
          if log.ingredient.id == recipe.ingredient.id && meal.id == log.meal.id
            assert_equal -recipe.amount*scheduled_menu.amount, log.amount
          end
        end
        restaurant_log.each do |log|
          if log.ingredient.id == recipe.ingredient.id && meal.id == log.meal.id
            assert_equal -recipe.amount*sold_menu.amount, log.amount
          end
        end
        num_of_ingredients += 1
      }
    end
    assert_equal num_of_ingredients, menu_log.size
  end

  def test_creating_scheduled_meals
    scheduled_menu = ScheduledMenu.create!(:menu => menus(:delikatni_menu), :amount => 10 ) {|sm| sm.scheduled_for = "2016-02-10"}
    sold_meal = RestaurantSale.create!(:premise => premises(:provozovna), :item_id => meals(:pecene_brambory).item_id, :sold_at => "2016-02-10", :amount => 5)
    scheduled_meals = ScheduledMeal.find :all, :conditions => ["scheduled_for = ? AND meal_id IN (?)", "2016-02-10", menus(:delikatni_menu).meal_ids - [meals(:pecene_brambory).item_id] ]
    assert_equal scheduled_meals, ScheduledMeal.find(:all, :conditions => ["scheduled_for = ?", "2016-02-10"])
    assert_equal 2, scheduled_meals.size
    assert_equal 5, scheduled_menu.reload.amount
    scheduled_meals.each do |sm|
      assert_equal 5, sm.amount
    end
    sold_meal.amount += 3
    sold_meal.save!
    scheduled_meals.each do |sm|
      assert_equal 8, sm.reload.amount
    end
    scheduled_meals = ScheduledMeal.find :all, :conditions => ["scheduled_for = ? AND meal_id IN (?)", "2016-02-10", menus(:delikatni_menu).meal_ids - [meals(:pecene_brambory).item_id] ]
    assert_equal scheduled_meals, ScheduledMeal.find(:all, :conditions => ["scheduled_for = ?", "2016-02-10"])
    assert_equal 2, scheduled_meals.size
    assert_equal 2, scheduled_menu.reload.amount
  end
  
  def test_selling_scheduled_bundle
    scheduled_bundle = ScheduledBundle.create!(:bundle => bundles(:troje_brambory), :amount => 30, :scheduled_for => "2119-02-11" )
    scheduled_meal = ScheduledMeal.find :first, :conditions => ["meal_id = ? AND scheduled_for = ?", scheduled_bundle.bundle.meal_id, "2119-02-11" ]
    assert_equal  scheduled_bundle.amount * scheduled_bundle.bundle.amount, scheduled_meal.amount
    sold_bundle = RestaurantSale.create!(:item_id => scheduled_bundle.bundle.item_id, :premise => premises(:provozovna), :sold_at => Date.parse("2119-02-11"), :amount => 10)
    assert_equal 20, scheduled_bundle.reload.amount
    assert_equal 20 * scheduled_bundle.bundle.amount, scheduled_meal.reload.amount
    
    sold_bundle.amount += 10
    sold_bundle.save!
    assert_valid sold_bundle
    assert_equal 10, scheduled_bundle.reload.amount
    assert_equal 10 * scheduled_bundle.bundle.amount, scheduled_meal.reload.amount
  end
end
