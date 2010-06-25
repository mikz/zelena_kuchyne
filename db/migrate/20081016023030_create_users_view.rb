class CreateUsersView < ActiveRecord::Migration
  def self.up
    sql_script 'users_view_up'
  end

  def self.down
    sql_script 'users_view_down'
  end
end
