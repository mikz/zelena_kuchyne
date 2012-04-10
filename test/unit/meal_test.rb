# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class MealTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_id_inheritance
    meal = Meal.find :first
    item = Item.find_by_item_id meal.item_id
    
    # AR implementation of id goes like this:
    # When id is first called, it redefines id (self) so it returns the class' primary key
    # Now, when you use inheritance and the class and it's superclass have 
    # different primary keys, very nasty thing can happen:
    # If you first ask the superclass for id, it's id method gets redefined to return it's primary key,
    # next, you ask the subclass for it's id and the method AR just created gets called and returns the superclass'
    # primary key as it was designed to do, not the sublclass' primary key and BOOM! ...everything goes to hell
    # 
    # This thing is especially common in production mode, where classes are not reloaded with each request
    item.id 
    
    assert_equal meal[:id], meal.id 
  end
end

