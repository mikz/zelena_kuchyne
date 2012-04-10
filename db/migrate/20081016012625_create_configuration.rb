# -*- encoding : utf-8 -*-
class CreateConfiguration < ActiveRecord::Migration
  def self.up
    sql_script 'configuration_up'
  end

  def self.down
    sql_script 'configuration_down'
  end
end

