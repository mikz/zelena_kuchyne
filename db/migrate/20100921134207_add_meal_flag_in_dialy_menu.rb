# -*- encoding : utf-8 -*-
class AddMealFlagInDialyMenu < ActiveRecord::Migration
  def self.up
    add_column MealFlag.table_name, :in_dialy_menu, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column MealFlag.table_name, :in_dialy_menu
  end
end

