class ScheduledItem < ActiveRecord::Base
  belongs_to :item
  set_primary_key 'item_id'
  set_table_name 'scheduled_items_view'
  
  def self.total *args
    args << {} unless args[1]
    args[1][:from] = "total_scheduled_meals_view"
    self.find(args[0],args[1])
  end
end
