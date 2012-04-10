# -*- encoding : utf-8 -*-
class CreateItemProfiles < ActiveRecord::Migration
  def self.up
    sql_script 'item_profiles_up'
  end

  def self.down
    sql_script 'item_profiles_down'
  end
end

