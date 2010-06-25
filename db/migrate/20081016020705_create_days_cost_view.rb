class CreateDaysCostView < ActiveRecord::Migration
  def self.up
    sql_script 'days_cost_view_up'
  end

  def self.down
    sql_script 'days_cost_view_down'
  end
end
