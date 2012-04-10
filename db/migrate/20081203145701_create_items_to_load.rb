# -*- encoding : utf-8 -*-
class CreateItemsToLoad < ActiveRecord::Migration
  def self.up
    sql_script 'assigned_ordered_meals_up'
    sql_script 'total_assigned_ordered_meals_functions_up'
    sql_script 'total_assigned_ordered_meals_up'
  end

  def self.down
    sql_script 'total_assigned_ordered_meals_down'
    sql_script 'total_assigned_ordered_meals_functions_down'
    sql_script 'assigned_ordered_meals_down'
  end
end

