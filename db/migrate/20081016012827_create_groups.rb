# -*- encoding : utf-8 -*-
class CreateGroups < ActiveRecord::Migration
  def self.up
    sql_script 'groups_up'
  end

  def self.down
    sql_script 'groups_down'
  end
end

