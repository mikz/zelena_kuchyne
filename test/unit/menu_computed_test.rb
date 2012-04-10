# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'
require "bigdecimal"

class MenuComputedTest < ActiveSupport::TestCase
  fixtures :users, :meals, :bundles
  ### actual tests
  
  def test_cost
    tested_menus = []
    tested_menus << menus(:pikantni_menu)
    tested_menus << menus(:delikatni_menu)
    
    for menu in tested_menus
      menu_computed = MenuComputed.find menu.id
      cost = BigDecimal.new("0")
      for meal in menu.meals
        cost += BigDecimal.new(meal.cost.to_s)
      end
      assert_equal cost, BigDecimal.new(menu_computed.cost.to_s)
    end
  end
  
  def test_meal_addition
    tested_menus = []
    tested_menus << menus(:pikantni_menu)
    tested_menus << menus(:delikatni_menu)
    meals = Meal.find :all
    for menu in tested_menus
      cost = BigDecimal.new("0")
      
      for meal in meals
        unless menu.meal_ids.include? meal.id
          menu.meals << meal 
          break
        end
      end
      
      for meal in menu.meals
        cost += BigDecimal.new(meal.cost.to_s)
      end
      
      meal.save
      menu_computed = MenuComputed.find menu.id
      assert_equal cost, BigDecimal.new(menu_computed.cost.to_s)
    end
  end
  
  def test_meal_remove
    tested_menus = []
    tested_menus << menus(:pikantni_menu)
    tested_menus << menus(:delikatni_menu)
    for menu in tested_menus
      menu_computed = MenuComputed.find menu.id
      meal = menu_computed.meals.first
      menu.meals.delete(meal)
      cost = BigDecimal.new(menu_computed.cost.to_s) - BigDecimal.new(meal.cost.to_s)
      menu_computed = MenuComputed.find menu.id
      
      assert_equal cost, BigDecimal.new(menu_computed.cost.to_s)
    end
  end
  
  def test_menu_update
    menu = menus(:delikatni_menu)
    menu_computed = MenuComputed.find menu.id
    menu_computed.update_attributes(:description => "F00BAR FReNzY!")
    menu_computed.save
    menu.reload
    assert_equal "F00BAR FReNzY!", menu.description
    
    menu_computed.price = 1337
    menu_computed.save
    menu.reload
    assert_equal menu.price, menu_computed.price
    assert_equal menu.price, 1337
  end
end

