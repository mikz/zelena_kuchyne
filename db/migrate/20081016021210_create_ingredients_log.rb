# -*- encoding : utf-8 -*-
class CreateIngredientsLog < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_log_up'
    sql_script 'ingredients_log_view_up'
    sql_script 'ingredients_log_full_view_up'
    sql_script 'ingredients_log_functions_up'
  end

  def self.down
    sql_script 'ingredients_log_full_view_down'
    sql_script 'ingredients_log_view_down'
    sql_script 'ingredients_log_functions_down'
    sql_script 'ingredients_log_down'
  end
end

