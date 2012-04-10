# -*- encoding : utf-8 -*-
class AddMealCategoryFacebookConfig < ActiveRecord::Migration
  def self.up
    add_column :meal_categories, :facebook, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :meal_categories, :facebook
  end
end

