class CreateDialyMenuEntryFlags < ActiveRecord::Migration
  def self.up
    create_table DialyMenuEntryFlag.table_name do |t|
      t.belongs_to :meal_flag, :null => false
      t.belongs_to :dialy_menu_entry, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table DialyMenuEntryFlag.table_name
  end
end
