# -*- encoding : utf-8 -*-
class DialyMenuEntry < ActiveRecord::Base  
  belongs_to :menu, :class_name => "DialyMenu"
  belongs_to :category, :class_name => "MealCategory"
  has_many :dialy_menu_entry_flags
  has_many :meal_flags, :through => :dialy_menu_entry_flags
  
  validates_presence_of :name, :price, :category
  validates_numericality_of :price
  validates_length_of :name, :within => 1..255
  
  alias_attribute :flags, :meal_flags
  
  def meal= meal
    %w{name price category}.each do |attr|
      self.send "#{attr}=", meal.send(attr)
    end
    
    self.meal_flags = meal.flags.select{ |flag| flag.in_dialy_menu? }
    
    %w{description}.each do |attr|
      DEBUG {%w{attr meal meal.send(attr) meal.description meal.item_profiles}}
      self.send "#{attr}=", Sanitize.clean(meal.send(attr)).gsub(" ", '').strip
    end
  end
end

