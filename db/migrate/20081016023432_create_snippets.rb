class CreateSnippets < ActiveRecord::Migration
  def self.up
    sql_script 'snippets_up'
  end

  def self.down
    sql_script 'snippets_down'
  end
end
