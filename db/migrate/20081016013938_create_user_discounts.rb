# -*- encoding : utf-8 -*-
class CreateUserDiscounts < ActiveRecord::Migration
  def self.up
    sql_script 'user_discounts_up'
  end

  def self.down
    sql_script 'user_discounts_down'
  end
end

