class CreateOrderedItems < ActiveRecord::Migration
  def self.up
    sql_script 'ordered_items_up'
    sql_script 'ordered_items_functions_up'
  end

  def self.down
    sql_script 'ordered_items_functions_down'
    sql_script 'ordered_items_down'
  end
end
