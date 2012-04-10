# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class OrderedItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end

  # tests ticket #115 problem
  def test_deleting_ordered_items_bug
    user = users(:martin)
    order = user.orders.create(:deliver_at => '2010-10-20')
    menu = scheduled_menus(:scheduled_menu_2).menu
    order.update_or_insert_items({menu.item_id => 1})
    ordered_items_before = order.ordered_items.reload.clone

    assert_equal 1, ordered_items_before.size

    buggy_meal = meals(:buggy_meal)
    buggy_meal.destroy

    assert_equal 1, order.ordered_items.reload.size
  end
end

