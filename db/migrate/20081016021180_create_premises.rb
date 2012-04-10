# -*- encoding : utf-8 -*-
class CreatePremises < ActiveRecord::Migration
  def self.up
    sql_script 'premises_up'
  end

  def self.down
    sql_script 'premises_down'
  end
end

