class CreateSpices < ActiveRecord::Migration
  def self.up
    sql_script 'spices_up'
  end

  def self.down
    sql_script 'spices_down'
  end
end
