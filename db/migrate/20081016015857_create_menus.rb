class CreateMenus < ActiveRecord::Migration
  def self.up
    sql_script 'menus_up'
  end

  def self.down
    sql_script 'menus_down'
  end
end
