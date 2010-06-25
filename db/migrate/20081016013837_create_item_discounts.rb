class CreateItemDiscounts < ActiveRecord::Migration
  def self.up
    sql_script 'item_discounts_up'
  end

  def self.down
    sql_script 'item_discounts_down'
  end
end
