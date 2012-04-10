# -*- encoding : utf-8 -*-
class CreateSoldItemsView < ActiveRecord::Migration
  def self.up
    sql_script 'sold_items_view_up'
  end

  def self.down
    sql_script 'sold_items_view_down'
  end
end

