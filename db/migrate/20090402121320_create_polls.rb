# -*- encoding : utf-8 -*-
class CreatePolls < ActiveRecord::Migration
  def self.up
    sql_script 'polls_up'
  end

  def self.down
    sql_script 'polls_down'
  end
end

