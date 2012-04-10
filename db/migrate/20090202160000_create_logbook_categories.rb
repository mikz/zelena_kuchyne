# -*- encoding : utf-8 -*-
class CreateLogbookCategories < ActiveRecord::Migration
  def self.up
    sql_script 'logbook_categories_up'
  end

  def self.down
    sql_script 'logbook_categories_down'
  end
end

