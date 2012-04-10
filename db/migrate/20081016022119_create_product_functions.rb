# -*- encoding : utf-8 -*-
class CreateProductFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'product_functions_up'
  end

  def self.down
    sql_script 'product_functions_down'
  end
end

