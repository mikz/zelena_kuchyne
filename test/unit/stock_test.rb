# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class StockTest < ActiveSupport::TestCase
  def test_view
    fake_controller_with_session_user(users(:martin))
    smeal = ScheduledMeal.create( :meal => meals(:smetanova_polevka), :amount => 50) {|sm| sm.scheduled_for = Date.today }
    assert_valid smeal
    smenu = ScheduledMenu.create( :menu => menus(:pikantni_menu), :amount => 110) { |sm| sm.scheduled_for = Date.today }
    assert_valid smenu
    lost_items = []
    
    lost_items.push LostItem.create( :item_id => meals(:smetanova_polevka).item_id, :amount => 10, :lost_at => Date.today, :user => users(:delivery_boy))
    assert_valid lost_items.last
    lost_items.push LostItem.create( :item_id => meals(:smetanova_polevka).item_id, :amount => 7, :lost_at => Date.today, :user => users(:delivery_girl))
    assert_valid lost_items.last
    lost_items.push LostItem.create( :item_id => meals(:zelnacka).item_id, :amount => 6, :lost_at => Date.today, :user => users(:delivery_girl))
    assert_valid lost_items.last
    lost_items.push LostItem.create( :item_id => meals(:zelnacka).item_id, :amount => 5, :lost_at => Date.today, :user => users(:delivery_boy))
    assert_valid lost_items.last
    
    sold_items = []
    sold_items.push SoldItem.create( :item_id => meals(:paprikovy_salat).item_id, :amount => 3, :sold_at => Date.today, :user => users(:delivery_boy))
    assert_valid SoldItem.last
    sold_items.push SoldItem.create( :item_id => meals(:paprikovy_salat).item_id, :amount => 12, :sold_at => Date.today, :user => users(:delivery_girl))
    assert_valid sold_items.last
    sold_items.push SoldItem.create( :item_id => meals(:gulas).item_id, :amount => 10, :sold_at => Date.today, :user => users(:delivery_boy))
    assert_valid sold_items.last
    sold_items.push SoldItem.create( :item_id => meals(:gulas).item_id, :amount => 8, :sold_at => Date.today, :user => users(:delivery_girl))
    assert_valid sold_items.last
    
    items_in_trunk = []
    items_in_trunk.push ItemInTrunk.create(:item_id => meals(:gulas).item_id, :amount => 4, :user => users(:delivery_girl), :deliver_at => Date.today)
    assert_valid items_in_trunk.last
    items_in_trunk.push ItemInTrunk.create(:item_id => meals(:gulas).item_id, :amount => 8, :user => users(:delivery_boy), :deliver_at => Date.today)
    assert_valid items_in_trunk.last
    items_in_trunk.push ItemInTrunk.create(:item_id => meals(:zelnacka).item_id, :amount => 1, :user => users(:delivery_girl), :deliver_at => Date.today)
    assert_valid items_in_trunk.last
    items_in_trunk.push ItemInTrunk.create(:item_id => meals(:zelnacka).item_id, :amount => 9, :user => users(:delivery_boy), :deliver_at => Date.today)
    assert_valid items_in_trunk.last
    
    
    stock = {}
    Stock.find_all_by_scheduled_for(Date.today).each {|val| stock[val.meal.item_id] = val}
    assert_equal 17, stock[meals(:smetanova_polevka).item_id].lost_amount
    assert_equal 11, stock[meals(:zelnacka).item_id].lost_amount
    assert_equal 15, stock[meals(:paprikovy_salat).item_id].sold_amount
    assert_equal 18, stock[meals(:gulas).item_id].sold_amount
    assert_equal 12, stock[meals(:gulas).item_id].in_trunk
    assert_equal 10, stock[meals(:zelnacka).item_id].in_trunk
  end
  
  
  def test_view_with_sold_menus
    smenu = ScheduledMenu.create( :menu => menus(:pikantni_menu), :amount => 100) { |sm| sm.scheduled_for = Date.today }
    assert_valid smenu
    lost_items = []
    
    lost_items.push LostItem.create( :item_id => meals(:zelnacka).item_id, :amount => 10, :lost_at => Date.today, :user => users(:delivery_boy))
    assert_valid lost_items.last
    lost_items.push LostItem.create( :item_id => menus(:pikantni_menu).item_id, :amount => 7, :lost_at => Date.today, :user => users(:delivery_girl))
    assert_valid lost_items.last
    
    sold_items = []
    sold_items.push SoldItem.create( :item_id => meals(:paprikovy_salat).item_id, :amount => 3, :sold_at => Date.today, :user => users(:delivery_boy))
    assert_valid SoldItem.last
    sold_items.push SoldItem.create( :item_id => menus(:pikantni_menu).item_id, :amount => 12, :sold_at => Date.today, :user => users(:delivery_girl))
    assert_valid sold_items.last
    
    
    stock = {}
    Stock.find_all_by_scheduled_for(Date.today).each {|val| stock[val.meal.item_id] = val}
    assert_equal 7, stock[meals(:paprikovy_salat).item_id].lost_amount
    assert_equal 17, stock[meals(:zelnacka).item_id].lost_amount
    assert_equal 15, stock[meals(:paprikovy_salat).item_id].sold_amount
    assert_equal 12, stock[meals(:zelnacka).item_id].sold_amount
  end
end

