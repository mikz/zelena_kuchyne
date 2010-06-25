class CreateWholesaleDiscounts < ActiveRecord::Migration
  def self.up
    sql_script 'wholesale_discounts_up'
    sql_script 'wholesale_discounts_functions_up'
  end

  def self.down
    sql_script 'wholesale_discounts_functions_down'
    sql_script 'wholesale_discounts_down'
  end
end
