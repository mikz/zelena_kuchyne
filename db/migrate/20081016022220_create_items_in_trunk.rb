# -*- encoding : utf-8 -*-
class CreateItemsInTrunk < ActiveRecord::Migration
  def self.up
    sql_script 'items_in_trunk_up'
  end

  def self.down
    sql_script 'items_in_trunk_down'
  end
end

