# -*- encoding : utf-8 -*-
class CreateMeals < ActiveRecord::Migration
  def self.up
    sql_script 'meals_up'
  end

  def self.down
    sql_script 'meals_down'
  end
end

