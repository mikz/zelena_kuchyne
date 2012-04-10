# -*- encoding : utf-8 -*-
class CreateIngredientsFullLogPerDayView < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_full_log_per_day_view_up'
    sql_script 'ingredients_full_log_per_day_view_functions_up'
    sql_script 'shopping_list_functions_up'
  end

  def self.down
    sql_script 'ingredients_full_log_per_day_view_functions_down'
    sql_script 'ingredients_full_log_per_day_view_down'
    sql_script 'shopping_list_functions_down'
  end
end

