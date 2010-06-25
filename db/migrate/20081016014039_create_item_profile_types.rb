class CreateItemProfileTypes < ActiveRecord::Migration
  def self.up
    sql_script 'item_profile_types_up'
  end

  def self.down
    sql_script 'item_profile_types_down'
  end
end
