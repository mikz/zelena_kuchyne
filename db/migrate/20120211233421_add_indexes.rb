# -*- encoding : utf-8 -*-
class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index(:items, :item_id)
    add_index(:meals, :id)
    add_index(:meals, :item_id)
    add_index(:meals, :name)
    add_index(:bundles, :id)
    add_index(:bundles, :item_id)
    add_index(:bundles, :meal_id)
    add_index(:courses, :meal_id)
    add_index(:ordered_items, :item_id)
    add_index(:lost_items, :item_id)

    #add_index(:orders, 'deliver_at')
    execute 'CREATE INDEX "index_orders_on_deliver_at_date" ON "orders" (CAST(deliver_at AS date))'
  end

  def self.down
    remove_index(:items, :item_id)
    remove_index(:meals, :id)
    remove_index(:meals, :item_id)
    remove_index(:meals, :name)
    remove_index(:bundles, :id)
    remove_index(:bundles, :item_id)
    remove_index(:bundles, :meal_id)
    remove_index(:courses, :meal_id)
    remove_index(:ordered_items, :item_id)
    remove_index(:lost_items, :item_id)

    execute 'DROP INDEX "index_orders_on_deliver_at_date"'
 end
end

