class AddDescriptionToMealCategory < ActiveRecord::Migration
  def self.up
    add_column :meal_categories, :description, :text
  end

  def self.down
    remove_column :meal_categories, :description
  end
end
