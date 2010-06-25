class CreateUserFunctions < ActiveRecord::Migration
  def self.up
    sql_script 'user_functions_up'
  end

  def self.down
    sql_script 'user_functions_down'
  end
end
