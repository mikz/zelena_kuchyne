class CreateItemTablesView < ActiveRecord::Migration
  def self.up
    sql_script 'item_tables_view_up'
  end

  def self.down
    sql_script 'item_tables_view_down'
  end
end
