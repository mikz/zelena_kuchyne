# -*- encoding : utf-8 -*-
class CreateZones < ActiveRecord::Migration
  def self.up
    sql_script 'zones_up'
  end

  def self.down
    sql_script 'zones_down'
  end
end

