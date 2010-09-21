class DialyMenuEntryFlag < ActiveRecord::Base
  belongs_to :meal_flag
  belongs_to :dialy_menu_entry
  
  validates_presence_of :meal_flag, :dialy_menu_entry
  validates_uniqueness_of :meal_flag_id, :scope => :dialy_menu_entry_id
  
end
