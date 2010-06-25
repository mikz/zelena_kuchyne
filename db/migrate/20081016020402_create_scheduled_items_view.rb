class CreateScheduledItemsView < ActiveRecord::Migration
  def self.up
    sql_script 'scheduled_items_view_up'
  end

  def self.down
    sql_script 'scheduled_items_view_down'
  end
end
