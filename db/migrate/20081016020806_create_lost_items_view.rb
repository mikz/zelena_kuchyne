class CreateLostItemsView < ActiveRecord::Migration
  def self.up
    sql_script 'lost_items_view_up'
  end

  def self.down
    sql_script 'lost_items_view_down'
  end
end
