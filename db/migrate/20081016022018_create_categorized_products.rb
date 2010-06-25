class CreateCategorizedProducts < ActiveRecord::Migration
  def self.up
    sql_script 'categorized_products_up'
  end

  def self.down
    sql_script 'categorized_products_down'
  end
end
