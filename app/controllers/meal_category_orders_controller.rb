# -*- encoding : utf-8 -*-
class MealCategoryOrdersController < ApplicationController
  include_javascripts 'jquery.tablesort'
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  
  def index
    @categories = MealCategoryOrder.all :order => "order_id ASC"
  end
  
  def update
    @categories = MealCategoryOrder.find(params[:categories].keys).index_by &:id
    MealCategoryOrder.transaction do
      params[:categories].each_pair do |id, order|
        category = @categories[id.to_i]
        category.order = order.to_i
        category.save(false)
      end
    end
    redirect_to :action => :index
    
  end
end

