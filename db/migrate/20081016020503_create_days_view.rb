class CreateDaysView < ActiveRecord::Migration
  def self.up
    sql_script 'days_view_up'
    sql_script 'days_functions_up'
  end

  def self.down
    sql_script 'days_functions_down'
    sql_script 'days_view_down'
  end
end
