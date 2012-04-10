# -*- encoding : utf-8 -*-
class CreateFuel < ActiveRecord::Migration
  def self.up
    sql_script 'fuel_up'
  end

  def self.down
    sql_script 'fuel_down'
  end
end

