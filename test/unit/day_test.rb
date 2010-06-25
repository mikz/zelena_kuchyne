require File.dirname(__FILE__) + '/../test_helper'

class DayTest < ActiveSupport::TestCase
  fixtures :scheduled_meals, :scheduled_menus
  
  def test_days
    all_days = Day.find(:all).collect {|d| d.scheduled_for.strftime("%Y-%m-%d")}
    
    scheduled_items = @loaded_fixtures['scheduled_meals'] + @loaded_fixtures['scheduled_menus']
    scheduled_items.each do |name, fixture|
      assert all_days.include?(fixture['scheduled_for'])
    end
  end
end
