# -*- encoding : utf-8 -*-
class CreateProducts < ActiveRecord::Migration
  def self.up
    sql_script 'products_up'
  end

  def self.down
    sql_script 'products_down'
  end
end

