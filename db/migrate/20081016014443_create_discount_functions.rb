# -*- encoding : utf-8 -*-
class CreateDiscountFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'discount_functions_up'
  end

  def self.down
    sql_script 'discount_functions_down'
  end
end

