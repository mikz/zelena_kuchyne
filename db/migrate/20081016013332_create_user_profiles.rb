# -*- encoding : utf-8 -*-
class CreateUserProfiles < ActiveRecord::Migration
  def self.up
    sql_script 'user_profiles_up'
  end

  def self.down
    sql_script 'user_profiles_down'
  end
end

