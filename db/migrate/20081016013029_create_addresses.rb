# -*- encoding : utf-8 -*-
class CreateAddresses < ActiveRecord::Migration
  def self.up
    sql_script 'addresses_up'
  end

  def self.down
    sql_script 'addresses_down'
  end
end

