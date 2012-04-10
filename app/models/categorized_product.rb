# -*- encoding : utf-8 -*-
class CategorizedProduct < ActiveRecord::Base
  set_primary_key 'oid'
  
  belongs_to :product_category
  belongs_to :product
end

