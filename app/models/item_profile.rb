# -*- encoding : utf-8 -*-
class ItemProfile < ActiveRecord::Base
  belongs_to :item
  belongs_to :item_profile_type, :foreign_key => 'field_type'
end

