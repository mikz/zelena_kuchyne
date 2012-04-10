# -*- encoding : utf-8 -*-
class CreateMealFlags < ActiveRecord::Migration
  def self.up
    sql_script 'meal_flags_up'
  end

  def self.down
    sql_script 'meal_flags_down'
  end
end

