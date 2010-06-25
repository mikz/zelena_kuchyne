class CreateProductCategories < ActiveRecord::Migration
  def self.up
    sql_script 'product_categories_up'
  end

  def self.down
    sql_script 'product_categories_down'
  end
end
