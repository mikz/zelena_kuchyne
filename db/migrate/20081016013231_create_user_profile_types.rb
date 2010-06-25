class CreateUserProfileTypes < ActiveRecord::Migration
  def self.up
    sql_script 'user_profile_types_up'
  end

  def self.down
    sql_script 'user_profile_types_down'
  end
end
