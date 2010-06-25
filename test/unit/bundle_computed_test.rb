require File.dirname(__FILE__) + '/../test_helper'

class BundleComputedTest < ActiveSupport::TestCase
  fixtures :users, :meals, :bundles
  ### actual tests
  
  def test_cost
    computed_bundle = BundleComputed.find(bundles(:troje_brambory).id)
    meal = meals(:pecene_brambory)
    
    assert_equal meal.cost.to_f * computed_bundle.amount, computed_bundle.cost
  end
  
  def test_update
    fake_controller_with_session_user(users(:peter))
    
    computed_bundle = BundleComputed.find(bundles(:troje_brambory).id)
    computed_bundle.amount = 4
    computed_bundle.save
    computed_bundle.reload
    
    assert_equal 4, computed_bundle.amount
    
    computed_bundle.update_attributes({:amount => 3})
    computed_bundle.reload
    
    assert_equal 3, computed_bundle.amount
  end
end
