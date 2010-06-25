class CreateDeliveryItemsView < ActiveRecord::Migration
  def self.up
    sql_script 'delivery_items_view_up'
  end

  def self.down
    sql_script 'delivery_items_view_down'
  end
end
