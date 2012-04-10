# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class AddressTest < ActiveSupport::TestCase
  fixtures :users, :addresses

  ### validity tests

  def test_valid_address
    address = addresses(:peter_home)
    assert_valid address
  end

  def test_invalid_formats    
    address = addresses(:peter_home)
    t = address.first_name
    address.first_name = "Invalid_name!"
    assert !address.valid?
    address.first_name = t

    t = address.family_name
    address.family_name = "Invalid_name!"
    assert !address.valid?
    address.family_name = t

    t = address.zip
    address.zip = "aaaaa"
    assert !address.valid?
    address.zip = "123456"
    assert !address.valid?
    address.zip = "12 345"
    assert !address.valid?
    address.zip = "1234"
    assert !address.valid?
    address.zip = "120 00"

    assert_valid address
    address.zip = t  

    assert_valid address
  end

  def test_missing_values  
    address = addresses(:peter_home)

    t = address.first_name
    address.first_name = ""
    assert !address.valid?
    address.first_name = t

    t = address.family_name
    address.family_name = ""
    assert !address.valid?
    address.family_name = t

    t = address.street
    address.street = ""
    assert !address.valid?
    address.street = t

    t = address.zip
    address.zip = ""
    assert !address.valid?
    address.zip = t

    t = address.house_no
    address.house_no = ""
    assert !address.valid?
    address.house_no = t

    t = address.city
    address.city = ""
    assert !address.valid?
    address.city = t

    assert_valid address
  end

  def test_too_long_values  
    address = addresses(:peter_home)

    t = address.first_name
    address.first_name = "a"*101
    assert !address.valid?
    address.first_name = t

    t = address.family_name
    address.family_name = "a"*101
    assert !address.valid?
    address.family_name = t

    t = address.street
    address.street = "a"*71
    assert !address.valid?
    address.street = t

    t = address.zip
    address.zip = "a"*31
    assert !address.valid?
    address.zip = t

    t = address.house_no
    address.house_no = "a"*16
    assert !address.valid?
    address.house_no = t

    t = address.city
    address.city = "a"*71
    assert !address.valid?
    address.city = t

    t = address.note
    address.note = "a"*101
    assert !address.valid?
    address.note = t

    assert_valid address
  end

  def test_value_presence_combination
    address = addresses(:peter_home)

    fn = address.first_name
    ln = address.family_name
    cn = address.company_name

    address.first_name = address.family_name = address.company_name = ""
    assert !address.valid?

    address.first_name = fn
    assert !address.valid?
    address.first_name = ""

    address.family_name = ln
    assert !address.valid?
    address.family_name = ""

    address.company_name = cn
    assert_valid address
    address.company_name = ""

    address.first_name = fn
    address.family_name = ln
    assert_valid address

    address.company_name = cn
    assert_valid address
  end

  def test_possible_address_types
    address = addresses(:peter_home)

    at = address.address_type

    %w{delivery billing home}.each do |type|
      address.address_type = type
      assert_valid address
    end

    address.address_type = "crazy_invalid_type"
    assert !address.valid?

    address.address_type = at
  end 

  def test_nonexistent_address
    address = addresses(:peter_home)

    address.street = "Falešná"
    address.house_no = "13"
    address.zip = "180 00"
    address.city = "Lživá ves u Falšova"
    address.district = "čtvrť zlosynů"
    
    Address.with_mapy_cz do
      begin
        assert !address.valid?
      rescue Test::Unit::AssertionFailedError => e
        STDERR << address.valid?.inspect
        raise e
      end 
    end
  end

  def test_input_value_types
    address  = Address.new(:user => users(:peter), :zone => zones(:zone3), :address_type => "delivery", :city => "Praha", :house_no => 45, :district => "Vinohrady", :street => "Jana Masaryka", :zip => 11000, :first_name => "", :company_name => "Singularis s.r.o.", :dont_validate =>  true)
    assert_valid address
    assert address.save
  end

  ### virtual attributes

  def test_output_format
    address = addresses(:peter_home)

    assert_equal address.output, %{Jana Masaryka 46 <br/>
      Praha, Vinohrady}
    end

    def test_attribute_presence_accessors
      address = addresses(:peter_home)

      assert address.first_name?

      address.first_name = ""
      assert !address.first_name?
    end                                 
  end

