# -*- encoding : utf-8 -*-
class CreateUsedSpices < ActiveRecord::Migration
  def self.up
    sql_script 'used_spices_up'
  end

  def self.down
    sql_script 'used_spices_down'
  end
end

