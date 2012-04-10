# -*- encoding : utf-8 -*-
class CreateStocktakings < ActiveRecord::Migration
  def self.up
    sql_script 'stocktakings_up'
    sql_script 'ingredients_log_from_stocktakings_up'
  end

  def self.down
    sql_script 'ingredients_log_from_stocktakings_down'
    sql_script 'stocktakings_down'
  end
end

