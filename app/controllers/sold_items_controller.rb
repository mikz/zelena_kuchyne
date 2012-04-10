# -*- encoding : utf-8 -*-
class SoldItemsController < ApplicationController
  before_filter(:only => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :deliverymen, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :deliverymen)}
  include_javascripts 'calendar_widget', 'jquery.autocomplete', 'lost_items', 'scheduled_items', 'fullscreen'
  include_stylesheets 'jquery-ui', 'jquery.autocomplete'
  exposure :title => "item", :columns => [:user, :sold_at, :amount]
  
  def index
    dates = CalendarWidget.parse params[:id]
    @dates = Day.find(:all, :order => :scheduled_for).collect {|day| day.scheduled_for }
    @sold_items = SoldItem.find :all, :conditions => ["sold_items.sold_at::date BETWEEN ? AND ?", dates[0], dates[1] ], :order => "sold_at ASC"
    
    respond_to do |format|
      format.html do
        render
      end
      format.js do
        render :update do |page|
          page.replace 'list', :partial => 'list'
        end
      end
    end
  end
  
  
  def new
    super
  end
  
  def create
    params[:record]['user'] = User.find_by_login(params[:record]['user'])
    @record = SoldItem.new(params[:record])
    super
  end
  
  def update
    params[:record]['user'] = User.find_by_login(params[:record]['user'])
    @record = SoldItem.find_by_oid(params[:id])
    super
  end
  
  
  def edit
    @record = SoldItem.find_by_oid params[:id]
    super
  end
end

