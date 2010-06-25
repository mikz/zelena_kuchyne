require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < ActiveSupport::TestCase
  fixtures :users, :meals, :orders
  
  def test_associations
    order = orders(:order_2)
    assert_equal users(:peter), order.user
    assert_equal order.ordered_items, OrderedItem.find_all_by_order_id(order.id)
    
  end
  
  def test_validation
    user = users(:peter)
    fake_controller_with_session_user(user)
    
    order = user.basket
    order.ordered_items.first.amount += 1000
    order.ordered_items.first.save
    
    assert !order.valid?
  end
  
  def test_items_update
    order = orders(:order_3)
    
    assert_equal [4], order.update_items(4 => 0, 7 => 2)
    assert order.ordered_items.select {|oi| oi.item_id == 4}.empty?
    assert_equal 2, order.ordered_items.select {|oi| oi.item_id == 7}.first.amount
  end
  
  def test_items_update_or_insertion
    order = orders(:order_3)
    
    order.update_or_insert_items(4 => 0, 7 => 2, 2 => 3)
    
    assert order.ordered_items.select {|oi| oi.item_id == 4}.empty?
    assert_equal 2, order.ordered_items.select {|oi| oi.item_id == 7}.first.amount
    assert_equal 3, order.ordered_items.select {|oi| oi.item_id == 2}.first.amount
  end
  
  def test_ordered_menus
    # TODO: I don't have a clue what order.ordered_menus does, the data structure it returns is ... fascinating
    # Someone else, and by someone I mean someone who knows what the method should do, had better write this test
  end
  
  def test_delivery_man_change
    delivery_girl = DeliveryMan.find(users(:delivery_girl).id)
    order = orders(:order_2)
    
    order.set_delivery_man_id delivery_girl.id
    order.save
    
    assert_equal delivery_girl.id, order.delivery_man.id
    assert !delivery_girl.delivery_items(order.deliver_at).empty?
    
    items = {2 => 4}
    delivery_girl.delivery_items(order.deliver_at).each do |item|
      assert items.has_key?(item.item_id)
      assert_equal items[item.item_id], item.amount
    end
  end
  
  def test_ordered_items_stock
    order = orders(:order_3)
    meal = meals(:smetanova_polevka)

    assumed_stock = {meal.item_id => 3}
    computed_stock = order.ordered_items_stock_levels
    assumed_stock.each do |id, amount|
      assert_equal amount, computed_stock[id].amount_left
    end
  end
  
  def test_items_not_in_stock
    order = orders(:order_3)
    meal = meals(:smetanova_polevka)
    
    oi = order.ordered_items.create({:item_id => meal.item_id, :amount => 3}) # should be fine (15 scheduled, 7 ordered, 3 lost and 2 sold)
    assert order.items_not_on_stock.empty?

    oi.amount += 1 # that should be too much
    oi.save
    assert !order.items_not_on_stock.empty?  
  end
  
  def test_ordered_items_hash
    order = orders(:order_3)
    
    oi_hash = {}
    order.ordered_items.each {|i| oi_hash[i.item_id] = i}
    
    assert_equal oi_hash, order.ordered_items_hash
  end
  
  def test_fix_amounts
    
  end
  
  def test_making_menus
    
  end

  def test_setting_delivery_man
    order = Order.create(:user => users(:martin), :deliver_at => Time.parse("2010-10-20 11:30"))
    order.ordered_items.create(:item_id => menus(:pikantni_menu).item_id, :amount => 4)
    order.ordered_items.create(:item_id => meals(:gulas).item_id, :amount => 1)
    assert_valid order

    order.set_delivery_man_id(users(:delivery_boy).id)
    items_in_trunk = {}
    ItemInTrunk.find_all_by_delivery_man_id(users(:delivery_boy)).each {|iit| items_in_trunk[iit.item_id] = iit }
    assert_equal 3, items_in_trunk[7].amount
    assert_equal 1, items_in_trunk[5].amount
    assert items_in_trunk[4].nil?

    order = Order.create(:user => users(:martin), :deliver_at => Time.parse("2010-10-20 11:30"))
    order.ordered_items.create(:item_id => menus(:delikatni_menu).item_id, :amount => 5)
    assert_valid order

    order.set_delivery_man_id(users(:delivery_girl).id)
    items_in_trunk = {}
    ItemInTrunk.find_all_by_delivery_man_id(users(:delivery_girl)).each {|iit| items_in_trunk[iit.item_id] = iit }
    assert_equal 5, items_in_trunk[4].amount
    assert_equal 5, items_in_trunk[2].amount
  end

  def test_deliver_at_validation
    order = orders(:order_7) # order's deliver_at time is 2010-10-30 11:30:00
    assert_valid order
   
    order.errors.clear
    order.validate_deliver_time(Time.parse("2010-10-30 10:29:00"))
    assert_valid order

    order.errors.clear
    order.validate_deliver_time(Time.parse("2010-10-30 10:30:00"))
    assert order.errors.on(:deliver_at)

    order.errors.clear
    order.validate_deliver_time(Time.parse("2010-10-30 10:35:00"))
    assert order.errors.on(:deliver_at)

    order.errors.clear
    order.validate_deliver_time(Time.parse("2010-10-30 11:45:00"))
    assert order.errors.on(:deliver_at)
  end
end
