class CreateLostItems < ActiveRecord::Migration
  def self.up
    sql_script 'lost_items_up'
  end

  def self.down
    sql_script 'lost_items_down'
  end
end
