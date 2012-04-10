# -*- encoding : utf-8 -*-
class CreateSoldItems < ActiveRecord::Migration
  def self.up
    sql_script 'sold_items_up'
  end

  def self.down
    sql_script 'sold_items_down'
  end
end

