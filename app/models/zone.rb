# -*- encoding : utf-8 -*-
class Zone < ActiveRecord::Base
  has_many :delivery_methods, :order => "minimal_order_price ASC"
  
  def number
    name.match(/\d+/).to_a.first
  end
end

