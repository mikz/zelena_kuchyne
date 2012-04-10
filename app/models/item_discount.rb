# -*- encoding : utf-8 -*-
class ItemDiscount < ActiveRecord::Base
    set_table_name 'item_discounts'
    belongs_to :item
    validates_presence_of :name, :amount, :start_at, :expire_at
    
    def amount
      super*100
    end
    
    def amount= value
      self[:amount] = value.to_f/100
    end
    
    def active? date
      return (start_at <= date and expire_at >= date) ? true : false
    end
      
end

