class CreateDialyMenuScheduleds < ActiveRecord::Migration
  def self.up
    sql_script 'dialy_menu_scheduled_up'
  end

  def self.down
    sql_script 'dialy_menu_scheduled_down'
  end
end
