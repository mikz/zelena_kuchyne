class DialyMenuEntry < ActiveRecord::Base
  belongs_to :menu, :class_name => "DialyMenu"
  belongs_to :category, :class_name => "MealCategory"

  validates_presence_of :name, :price, :category
  validates_numericality_of :price
  validates_length_of :name, :within => 1..255
  
end
