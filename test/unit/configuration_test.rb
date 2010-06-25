require File.dirname(__FILE__) + '/../test_helper'

class ConfigurationTest < ActiveSupport::TestCase
  fixtures :configuration
  
  def test_single_values
    assert_equal 'cs', Configuration.default_language
    assert_equal '10:30', Configuration.delivery_from
    assert_equal '15:30', Configuration.delivery_to
    assert_equal '1800', Configuration.delivery_step
    assert_equal '30', Configuration.default_pagination
  end
                                     
  def test_values
    values = {:default_language => 'cs', :delivery_from => '10:30', :delivery_to => '15:30', :delivery_step => '1800', :default_pagination => '30'}      
    assert_equal values, Configuration.values
  end
  
  def test_values_update
    new_values = {:default_language => 'en', :delivery_from => '10:00', :delivery_to => '15:00', :delivery_step => '3600', :default_pagination => '50'}
    old_values = Configuration.values
    
    new_values.each do |key, value|
       Configuration.send("#{key.to_s}=", value)
       assert_equal value, Configuration.send(key) 
    end
    
    assert_equal new_values, Configuration.values
  end

  def test_delivery
    delivery = {
      :from =>  Time.parse('10:30'),
      :from_orig => '10:30',
      :to => Time.parse('15:30'),
      :to_orig => '15:30',
      :step => 1800,
      :last => Time.parse('14:30')
    }
    
    assert_equal delivery, Configuration.delivery
  end
end
