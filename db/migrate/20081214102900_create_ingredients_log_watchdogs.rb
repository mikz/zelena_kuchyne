# -*- encoding : utf-8 -*-
class CreateIngredientsLogWatchdogs < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_log_watchdogs_up'
    sql_script 'ingredients_log_watchdogs_functions_up'
    sql_script 'ingredients_log_watchdogs_view_up'
  end

  def self.down
    sql_script 'ingredients_log_watchdogs_functions_down'
    sql_script 'ingredients_log_watchdogs_view_down'
    sql_script 'ingredients_log_watchdogs_down'
  end
end

