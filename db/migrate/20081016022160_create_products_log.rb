class CreateProductsLog < ActiveRecord::Migration
  def self.up
    sql_script 'products_log_up'
    sql_script 'products_log_functions_up'
  end

  def self.down
    sql_script 'products_log_down'
    sql_script 'products_log_functions_down'
  end
end
