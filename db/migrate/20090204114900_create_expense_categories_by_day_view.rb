# -*- encoding : utf-8 -*-
class CreateExpenseCategoriesByDayView < ActiveRecord::Migration
  def self.up
    sql_script 'expense_categories_by_day_view_up'
  end

  def self.down
    sql_script 'expense_categories_by_day_view_down'
  end
end

