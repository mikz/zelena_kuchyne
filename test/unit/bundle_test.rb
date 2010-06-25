require File.dirname(__FILE__) + '/../test_helper'

class BundleTest < ActiveSupport::TestCase
  fixtures :meals, :bundles
  
  def test_cost
    bundle = bundles(:troje_brambory)
    meal = meals(:pecene_brambory)
    
    assert_equal bundle.cost, (meal.cost.to_f * bundle.amount).to_s
  end
end
