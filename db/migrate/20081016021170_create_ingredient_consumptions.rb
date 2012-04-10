# -*- encoding : utf-8 -*-
class CreateIngredientConsumptions < ActiveRecord::Migration
  def self.up
    sql_script 'ingredient_consumptions_up'
  end

  def self.down
    sql_script 'ingredient_consumptions_down'
  end
end

