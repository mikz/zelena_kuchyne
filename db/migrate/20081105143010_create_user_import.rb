# -*- encoding : utf-8 -*-
class CreateUserImport < ActiveRecord::Migration
  def self.up
    sql_script 'user_import_up'
  end

  def self.down
    sql_script 'user_import_down'
  end
end

