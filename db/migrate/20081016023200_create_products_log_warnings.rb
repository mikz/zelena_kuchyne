class CreateProductsLogWarnings < ActiveRecord::Migration
  def self.up
    sql_script 'products_log_warnings_up'
    sql_script 'products_log_warnings_view_up'
  end

  def self.down
    sql_script 'products_log_warnings_down'
    sql_script 'products_log_warnings_view_down'
  end
end
