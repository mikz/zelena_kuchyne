# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class DeliveryManTest < ActiveSupport::TestCase
  fixtures :users, :orders
  
  def test_finder
    dm = DeliveryMan.find :all
    dm.each do |m|
      assert m.groups.collect {|g| g.system_name }.include?('deliverymen')
    end
  end
  
  def test_delivery_items
    dm = DeliveryMan.find(users(:delivery_boy).id)
    order = orders(:order_2)
    date = order.deliver_at
    
    dm.delivery_items(date).each do |item|
      assert_equal date.year, item.scheduled_for.year
      assert_equal date.month, item.scheduled_for.month
      assert_equal date.day, item.scheduled_for.day
      assert_equal dm.id, item.delivery_man_id
    end
  end
  
  def test_orders_for_date
    dm = DeliveryMan.find(users(:delivery_boy).id)
    order = orders(:order_2)
    date = order.deliver_at
    
    dm.orders_for_date(date).each do |order|
      assert ['order', 'expedited', 'closed'].include?(order.state)
      assert_equal dm.id, order.delivery_man_id
      assert_equal date.year, order.deliver_at.year
      assert_equal date.month, order.deliver_at.month
      assert_equal date.day, order.deliver_at.day
    end
  end
  
  def test_sum_price
    dm = DeliveryMan.find(users(:delivery_boy).id)
    order = orders(:order_2)
    date = order.deliver_at
    
    price = dm.orders_for_date(date).collect {|order| order.price }.sum
    assert_equal price, dm.sum_price(date)
  end
end

