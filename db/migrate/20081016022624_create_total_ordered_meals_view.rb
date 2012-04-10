# -*- encoding : utf-8 -*-
class CreateTotalOrderedMealsView < ActiveRecord::Migration
  def self.up
    sql_script 'total_ordered_meals_view_up'
  end

  def self.down
    sql_script 'total_ordered_meals_view_down'
  end
end

