# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
  fixtures :users, :meals, :meal_categories
  
  def test_item_type
    meal = meals(:pecene_brambory)
    item = Item.find_by_item_id meal.item_id

    assert meal.meal?
    assert item.meal?
    assert !meal.menu?
    assert !item.menu?
    assert !meal.bundle?
    assert !item.bundle?
    assert !meal.product?
    assert !item.product?
    
    meal = menus(:delikatni_menu)
    item = Item.find_by_item_id meal.item_id
    
    assert !meal.meal?
    assert !item.meal?
    assert meal.menu?
    assert item.menu?
    assert !meal.bundle?
    assert !item.bundle?
    assert !meal.product?
    assert !item.product?
    
  end
  
  def test_item_profiles
    fake_controller_with_session_user(users(:martin))
    pecene_brambory = meals(:pecene_brambory)
    
    assert !pecene_brambory.recipe?
    
    pecene_brambory.recipe = 'recept na brambory';
    pecene_brambory.save
    
    assert pecene_brambory.recipe?
    assert_equal 'recept na brambory', pecene_brambory.item_profiles.detect{|p| p.item_profile_type.name == 'recipe'}.field_body
    assert_equal 'recept na brambory', pecene_brambory.recipe
  end
  
  def test_item_id_after_create
    fake_controller_with_session_user(users(:martin))
    meal_attr = {:name => "krvavá polévka", :price => 20, :meal_category => meal_categories(:polevky)}
    
    m = Meal.new(meal_attr)
    assert m.item_id.nil?
    
    m.save
    assert !m.item_id.nil?
  end
  
  def test_associations
    soup = meals(:smetanova_polevka)
    potatoes = meals(:pecene_brambory)
    
    profiles = ItemProfile.find(:all, :conditions => ['item_id = ?', potatoes.item_id])
    assert_equal profiles, potatoes.item_profiles.to_a
    
    ordered_items = OrderedItem.find(:all, :conditions => ['item_id = ?', soup.item_id])
    assert_equal ordered_items, soup.ordered_items.to_a
    
    discounts = ItemDiscount.find(:all, :conditions => ['item_id = ?', soup.item_id])
    assert_equal discounts, soup.item_discounts.to_a
  end
  
  def test_last_updated_by
    peter = users(:peter)
    fake_controller_with_session_user(peter)
    soup = meals(:smetanova_polevka)
    
    soup.recipe = "Recept na smetanovou polévku"
    soup.save
    
    assert_equal peter, soup.last_update_by
  end
  
  def test_item_discount_price
    peter = users(:peter)
    fake_controller_with_session_user(peter)
    date = Date.parse('2010-10-20') # that's when peter has a discount of 33%
    
    user_discount = peter.active_discounts(:date => date, :item_type => 'meal').first
    
    soup = meals(:smetanova_polevka) # should have 15% discount on 2010-10-20
    
    soup_discount = ItemDiscount.find(:all, :conditions => ['item_id = ? AND start_at <= ? AND COALESCE(?, expire_at) >= ?', soup.item_id, date, date, date]).first
    
    sum_discount = (user_discount.amount + soup_discount.amount)/100
    price = ([1 - sum_discount, 0].max) * soup.price 
    
    assert_equal price, soup.discount_price(:date => date, :user => peter)
  end
end

