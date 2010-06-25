require File.dirname(__FILE__) + '/../test_helper'

class OrderViewTest < ActiveSupport::TestCase
  fixtures :users, :orders
  
  def test_sum_for_user
    martin = users(:martin)
    order = orders(:order_2)
    
    sum = compute_user_orders_price(martin)
    assert_equal sum, OrderView.sum_for_user(martin)
  end
  
  def compute_user_orders_price(user)
    orders = user.orders.select {|o| o.state == 'closed' and !o.cancelled }
    ids = orders.collect {|o| o.id}
    dm_price = orders.collect {|o| o.delivery_method ? o.delivery_method.price : 0.0}.sum
    
    items = OrderedItemView.find(:all, :conditions => "order_id IN (#{ids.join(',')})")
    
    sum = items.collect {|i| i.discount_price * i.amount}.sum + dm_price
  end
  
  def test_changing_item_price
    order = orders(:order_1)
    order_view = order.order_view
    menu = menus(:pikantni_menu)
    old_price = order_view.price
    menu.price = menu.price + 50
    menu.save
    order_view.reload
    assert_equal old_price, order_view.price
  end
  
  def test_changing_ordered_item_price
    order = orders(:order_3)
    order_view = order.order_view
    ordered_item = order.ordered_items.first
    ordered_item.price += 50.25
    ordered_item.save!
    old_price = old_price = order_view.price
    order_view.reload
    assert_equal old_price + ordered_item.amount*50.25, order_view.price
  end
end
