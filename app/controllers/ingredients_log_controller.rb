class IngredientsLogController < ApplicationController
  before_filter{ |c| c.must_belong_to_one_of(:admins, :warehousers, :operating_officers)}
  
  include_javascripts 'calendar_widget', 'fullscreen'
  include_stylesheets 'jquery-ui'
  include FilterWidget
  
  exposure :model => "IngredientsLogEntry".constantize, :title => "day", :columns => [:day,:amount,:cost_per_unit, :total_cost, :notes]
  
  def index
    redirect_to :action => "per_day"
  end
  
  def watchdogs
    
    order = (params[:order].blank?)? "ingredients.name ASC": params[:order]
    @records = IngredientsLogWatchdogView.check_date((params[:date].blank?)? Date.today : Date.parse(params[:date]))
    @days = IngredientsLogEntry.balance_days
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace 'watchdogs', :partial => "watchdogs"
        end
      end
      format.xml do
        render :xml => @records
      end
    end
  end
  
  def per_day
    dates = CalendarWidget.parse params[:date]
    conditions = []
    conditions.push "day BETWEEN '#{dates[0].to_s}' AND '#{dates[1].to_s}'" unless dates == [Date.today,Date.today]
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    order = (params[:order].blank?)? "day": params[:order] +" DESC"
    
    @records = IngredientsLogEntry.full_log_per_day :conditions => conditions, :order => order, :page => params[:page]
    log
  end
  
  def per_meal
    dates = CalendarWidget.parse params[:date]
    conditions = []
    conditions.push "day BETWEEN '#{dates[0].to_s}' AND '#{dates[1].to_s}'" unless dates == [Date.today,Date.today]
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    order = (params[:order].blank?)? "day": params[:order] +" DESC"

    @records = IngredientsLogEntry.full_log_per_meal :conditions => conditions, :order => order, :page => params[:page]
    log
  end
  
  def log
    @days = IngredientsLogEntry.full_log_days
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'ingredients_log', :partial => 'log'
          page << "var calendar_widget_url = #{url_for(params.merge({'date' => '__date__'})).gsub('&amp;', '&').inspect};"
          page << "filterWidget('records-rules').updateOptions({url: #{url_for(params.delete_if {|key,val| key == 'filter'}).gsub('&amp;', '&').inspect}});"
        end
      end
      format.html do
        render :action => "log"
      end
      format.xml do
        render :xml => @records
      end
    end
  end
  
  def new
    @ingredients = Ingredient.find :all, :order => "name ASC"
    @record = IngredientsLogEntry.new
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def edit
    @ingredients = Ingredient.find :all, :order => "name ASC"
    @record = IngredientsLogEntry.find_by_id params[:id]
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    case params[:cost]["type"]
      when "auto"
      when "total"
        params[:record]["ingredient_price"] = params[:cost]["value"].to_f / params[:record]["amount"].to_f
      when "unit"
        params[:record]["ingredient_price"] = params[:cost]["value"]
    end if params[:cost]
    update_ingredient = !params[:update_ingredient_cost].nil?
    
    super
    
    if update_ingredient
      @record.ingredient.cost = @record.ingredient_price
      @record.ingredient.save
    end
  end
  
  def update
    case params[:cost]["type"]
      when "auto"
      when "total"
        params[:record]["ingredient_price"] = params[:cost]["value"].to_f / params[:record]["amount"].to_f
      when "unit"
        params[:record]["ingredient_price"] = params[:cost]["value"]
    end if params[:cost]
    update_ingredient = !params[:update_ingredient_cost].nil?
    
    super
    
    if update_ingredient
      @record.ingredient.cost = @record.ingredient_price
      @record.ingredient.save
    end
  end
  
  def balance
    order = (params[:order].blank?)? "ingredient_id ASC": params[:order]
    
    @records = IngredientsLogEntry.balance :day => params[:date] || Date.today , :order => order, :page => params[:page]
    @days = IngredientsLogEntry.balance_days
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace 'ingredients_log', :partial => "balance"
        end
      end
      format.xml do
        render :xml => @records
      end
    end
  end
end
