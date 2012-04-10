# -*- encoding : utf-8 -*-
class CreateOrderFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'order_functions_up'
  end

  def self.down
    sql_script 'order_functions_down'
  end
end

