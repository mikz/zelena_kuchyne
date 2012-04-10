# -*- encoding : utf-8 -*-
class MenuComputed < Menu
  set_primary_key 'id'
  set_table_name 'menus_view'
  has_many :courses, :foreign_key => "menu_id"
  has_many :meals, :foreign_key => "menu_id", :class_name => "MealComputed", :through => :courses
  
  def save
    menu = self.becomes(Menu)
    self.changed.each { |attr|
      menu.send "#{attr}_will_change!"
    }
    menu.save
    self.reload
  end
  
  def update_attributes attrs
    self.becomes(Menu).update_attributes attrs
    save
  end
  
  def cost
    self[:cost]
  end  
end

