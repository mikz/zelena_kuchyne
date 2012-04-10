# -*- encoding : utf-8 -*-
class CreateScheduledMealsLeftView < ActiveRecord::Migration
  def self.up
    sql_script 'sold_meals_view_up'
    sql_script 'lost_meals_view_up'
    sql_script 'scheduled_meals_left_view_up'
  end

  def self.down
    sql_script 'sold_meals_view_down'
    sql_script 'lost_meals_view_down'
    sql_script 'scheduled_meals_left_view_down'
  end
end

