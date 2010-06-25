class CreateProductsLogViews < ActiveRecord::Migration
  def self.up
    sql_script 'products_log_view_up'
  end

  def self.down
    sql_script 'products_log_view_down'
  end
end
