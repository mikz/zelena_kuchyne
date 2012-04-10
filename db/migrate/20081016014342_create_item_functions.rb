# -*- encoding : utf-8 -*-
class CreateItemFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'item_functions_up'
  end

  def self.down
    sql_script 'item_functions_down'
  end
end

