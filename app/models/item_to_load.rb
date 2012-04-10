# -*- encoding : utf-8 -*-
class ItemToLoad < ActiveRecord::Base
  set_table_name 'total_assigned_ordered_meals'
  set_primary_key 'delivery_man_id'
  belongs_to :delivery_man
  belongs_to :item
  belongs_to :user, :foreign_key => "delivery_man_id"
end

