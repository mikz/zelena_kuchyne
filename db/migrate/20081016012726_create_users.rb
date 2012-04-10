# -*- encoding : utf-8 -*-
class CreateUsers < ActiveRecord::Migration
  def self.up
    sql_script 'users_up'
  end

  def self.down
    sql_script 'users_down'
  end
end

