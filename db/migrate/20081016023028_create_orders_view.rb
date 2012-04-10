# -*- encoding : utf-8 -*-
class CreateOrdersView < ActiveRecord::Migration
  def self.up
    sql_script 'orders_view_up'
  end

  def self.down
    sql_script 'orders_view_down'
  end
end

