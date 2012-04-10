# -*- encoding : utf-8 -*-
class CreateRecipes < ActiveRecord::Migration
  def self.up
    sql_script 'recipes_up'
  end

  def self.down
    sql_script 'recipes_down'
  end
end

