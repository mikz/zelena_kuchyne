require File.dirname(__FILE__) + '/../test_helper'

class ItemDiscountTest < ActiveSupport::TestCase
  fixtures :item_discounts
  
  def test_active
    item_d = item_discounts(:item_discount_0)
    s_date = item_d.start_at
    e_date = item_d.expire_at
    m_date = s_date + (e_date - s_date)/2
    
    assert item_d.active?(m_date)
    assert item_d.active?(s_date)
    assert item_d.active?(e_date)
  end
  
end
