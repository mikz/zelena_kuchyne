# -*- encoding : utf-8 -*-
class CreateOrderedItemsView < ActiveRecord::Migration
  def self.up
    sql_script 'ordered_items_view_up'
  end

  def self.down
    sql_script 'ordered_items_view_down'
  end
end

