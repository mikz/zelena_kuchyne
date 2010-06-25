class CreateExpenses < ActiveRecord::Migration
  def self.up
    sql_script 'expenses_up'
  end

  def self.down
    sql_script 'expenses_down'
  end
end
