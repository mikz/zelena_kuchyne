require 'better_migrations/sql_files'

module BetterMigrations
  include ActiveRecord
  
  class SQLFileNotFoundError < ActiveRecordError
  end
  
  def self.included(base)
    base.class_eval do
      include BetterMigrations::SQLFiles
    end
  end
end