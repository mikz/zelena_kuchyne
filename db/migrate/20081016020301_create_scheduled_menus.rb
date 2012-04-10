# -*- encoding : utf-8 -*-
class CreateScheduledMenus < ActiveRecord::Migration
  def self.up
    sql_script 'scheduled_menus_up'
    sql_script 'scheduled_menus_functions_up'
  end

  def self.down
    sql_script 'scheduled_menus_functions_down'
    sql_script 'scheduled_menus_down'
  end
end

