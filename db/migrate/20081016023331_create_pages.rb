# -*- encoding : utf-8 -*-
class CreatePages < ActiveRecord::Migration
  def self.up
    sql_script 'pages_up'
  end

  def self.down
    sql_script 'pages_down'
  end
end

