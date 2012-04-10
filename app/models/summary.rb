# -*- encoding : utf-8 -*-
class Summary < ActiveRecord::Base
  set_table_name "summary_view"
  
  def self.between(from, to)
    @between = {}
    self.find(:first, :from => "get_summary_between(#{self.connection.quote(from)}, #{self.connection.quote(to)})").attributes.each_pair { |key,sum| @between[key.to_sym] = sum }
    delivery = [:delivery_ingredients, :lost_items, :fuel, :orders_price, :delivery_sold_items, :delivery_expences ]
    restaurant = [:restaurant_sales, :restaurant_ingredients ]
    @between.each do |key,val| 
      @between[key] = val.to_f
    end
    @between[:delivery_summary] = @between[:orders_price] + @between[:delivery_sold] - @between[:delivery_expenses] - @between[:delivery_cooking_ingredients] - @between[:fuel] 
    @between[:restaurant_summary] = @between[:restaurant_sold] + @between[:restaurant_sales] - @between[:restaurant_cooking_ingredients] - @between[:restaurant_expenses] 
    @between[:office_summary] = 0 - @between[:office_expenses]
    @between
  end
  
  def self.average_day(from, to)
    @average_day = between(from, to)
    days = Day.between(from, to)
    @average_day.each_pair do |key, val|
      @average_day[key] = val/days.size
    end
    @average_day
  end
end

