# -*- encoding : utf-8 -*-
class CreateIngredientsPerDayView < ActiveRecord::Migration
  def self.up
    sql_script 'ingredients_per_day_view_up'
  end

  def self.down
    sql_script 'ingredients_per_day_view_down'
  end
end

