class CreateSuppliers < ActiveRecord::Migration
  def self.up
    sql_script 'suppliers_up'
  end

  def self.down
    sql_script 'suppliers_down'
  end
end
