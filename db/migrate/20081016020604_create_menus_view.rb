class CreateMenusView < ActiveRecord::Migration
  def self.up
    sql_script 'menus_view_up'
  end

  def self.down
    sql_script 'menus_view_down'
  end
end
