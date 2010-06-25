class CreateDeliveryMethods < ActiveRecord::Migration
  def self.up
    sql_script 'delivery_methods_up'
  end

  def self.down
    sql_script 'delivery_methods_down'
  end
end
