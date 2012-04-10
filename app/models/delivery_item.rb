# -*- encoding : utf-8 -*-
class DeliveryItem < ActiveRecord::Base
  set_table_name 'delivery_items_view'
  set_primary_key 'item_id'
  belongs_to :item
  has_one :delivery_man

end

