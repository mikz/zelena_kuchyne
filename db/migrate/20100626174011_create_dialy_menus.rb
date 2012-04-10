# -*- encoding : utf-8 -*-
class CreateDialyMenus < ActiveRecord::Migration
  def self.up
    sql_script 'dialy_menus_up'
  end

  def self.down
    sql_script 'dialy_menus_down'
  end
end

