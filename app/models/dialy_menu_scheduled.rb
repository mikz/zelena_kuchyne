class DialyMenuScheduled < ActiveRecord::Base
  set_table_name "dialy_menu_scheduled"
  
  belongs_to :menu, :class_name => "DialyMenu"
end
