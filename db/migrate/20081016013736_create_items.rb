# -*- encoding : utf-8 -*-
class CreateItems < ActiveRecord::Migration
  def self.up
    sql_script 'items_up'
  end

  def self.down
    sql_script 'items_down'
  end
end

