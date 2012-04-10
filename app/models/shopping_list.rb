# -*- encoding : utf-8 -*-
class ShoppingList < ActiveRecord::Base
  set_table_name 'ingredients_per_day_view'
  
  def self.between date1, date2, params={}
    params = {} unless params
    params[:from] = "get_shopping_list_between('#{date1.to_s}', '#{date2.to_s}')"
    self.find :all, params
  end

  def self.sum_between date1, date2, params={}
    params = {} unless params
    params[:select] = "SUM(total_cost) as sum, SUM(total_cost_with_consumption) as sum_with_consumption"
    params[:from] = "get_shopping_list_between('#{date1.to_s}', '#{date2.to_s}')"
    self.find :first, params    
  end
end

