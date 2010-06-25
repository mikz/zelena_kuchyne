class CreateOrders < ActiveRecord::Migration
  def self.up
    sql_script 'orders_up'
  end

  def self.down
    sql_script 'orders_down'
  end
end
