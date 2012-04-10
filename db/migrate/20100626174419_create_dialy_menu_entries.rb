# -*- encoding : utf-8 -*-
class CreateDialyMenuEntries < ActiveRecord::Migration
  def self.up
    sql_script 'dialy_menu_entries_up'
  end

  def self.down
    sql_script 'dialy_menu_entries_down'
  end
end

