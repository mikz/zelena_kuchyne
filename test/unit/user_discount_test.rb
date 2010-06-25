require File.dirname(__FILE__) + '/../test_helper'

class UserDiscountTest < ActiveSupport::TestCase
  fixtures :users
  
  def test_overlapping_discount
    peter = users(:peter)
    ud_attr = {:start_at => '2010-10-20', :expire_at => '2010-10-30', :amount => 20, :name => '20% sleva mezi 20. 10. 2010 a 30. 10. 2010', :discount_class => 'meal'}
    ud = peter.user_discounts.new(ud_attr)
    assert !ud.valid?
    
    ud.start_at = '2010-09-01'
    assert !ud.valid?
    
    ud.expire_at = '2010-09-30'
    ud.name = '20% sleva mezi 20. 10. 2010 a 30. 10. 2010'
    assert_valid ud
  end
  
  def test_infinite_discount_in_the_future
    peter = users(:peter)
    ud_attr = {:start_at => '2011-01-01', :amount => 15, :name => 'Doživotní 15% sleva na jídlo od 1.1.2011', :discount_class => 'meal'}
    ud = peter.user_discounts.new(ud_attr)
    assert_valid ud
    ud.save
    
    ud_attr[:start_at] = '2010-08-20'
    ud_attr[:expire_at] = '2010-08-31'
    ud2 = peter.user_discounts.new(ud_attr)
    assert_valid ud2
  end
end