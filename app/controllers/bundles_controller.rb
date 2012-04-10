# -*- encoding : utf-8 -*-
class BundlesController < ApplicationController
  before_filter(:only => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'fullscreen'
  exposure :columns => [:meal, :amount, :price, :updated_at]
  
  def index
    @records = BundleComputed.paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting, :order => (params[:order] ? "bundles_view."+params[:order] : 'bundles_view.name') + ' ASC', :include => [:last_update_by])
    super
  end
  
  def edit
    @meals = Meal.find :all, :order => "name ASC"
    @record = Bundle.find_by_id params[:id], :include => [:meal]
    super
  end
  
  def new
    @meals = Meal.find :all
  end
  
  def create
    @record = Bundle.new(params[:record])
    if(@record.save)
      @record.meal = Meal.find params[:record]['meal_id']
    end
    super
  end
  
  def update
    @record = Bundle.find_by_id params[:id], :include => [:meal]
    if(@record.update_attributes(params[:record]))
      @record.meal = Meal.find params[:record]['meal_id']
    end
    super
  end
end

