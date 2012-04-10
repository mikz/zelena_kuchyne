# -*- encoding : utf-8 -*-
class CreateMemberships < ActiveRecord::Migration
  def self.up
    sql_script 'memberships_up'
  end

  def self.down
    sql_script 'memberships_down'
  end
end

