# -*- encoding : utf-8 -*-
class RestaurantSalesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :operating_officers)}
  include_javascripts 'jquery.autocomplete', 'calendar_widget', "scheduled_items", "fullscreen"
  include_stylesheets 'jquery.autocomplete', 'jquery-ui'
  include FilterWidget

  exposure({
    :title => {:name => "sold_at", :options => {:formatter => "date"}},
    :columns => [
      { :name => :amount, :options => {:formatter => :amount} },
      { :name => :item , :proc => Proc.new {|i| i.name }},
      { :name => :price, :options => {:formatter => :currency}},
      { :name => :buyer_login, :order => "users.login"}
    ],
    :form_fields => [
      { :name => :sold_at, :type => :text_field, :options => {:class => "datepicker", :onchange => 'scheduled_items.load(this.value, \'##{row_id}_item\', true);'} },
      { :name => :item, :type => :select, :data_proc => Proc.new {Meal.find(:all,:order => "name ASC", :conditions => "restaurant_flag = true").collect{|m| [ m.name, m.item_id ] } } },
      { :name => :amount, :type => :text_field , :note => :amount_unit},
      { :name => :price, :type => :text_field , :note => :currency_unit},
      { :name => :premise, :type => :select, :data_proc =>  Proc.new {Premise.find(:all,:order => "name ASC").collect{|p| [ p.name, p.id ] } } },
      { :name => :buyer_login, :type => :text_field, :options => {:class => "autocomplete"}},
      { :name => :note, :type => :text_field }
     ],
    :form => {:onload => %{$(".datepicker").datepicker();$('.autocomplete').autocomplete('/users/find/');}},
    :calendar_widget => true,
    :dates_proc => Proc.new{Day.find(:all, :order => :scheduled_for).collect{|day| day.scheduled_for } },
    :date_column => "sold_at",
    :include => [:buyer, :premise, :item],
    :joins => "LEFT JOIN meals ON restaurant_sales.item_id = meals.item_id"
  })
  
  def index
    @dates = Day.find(:all, :order => :scheduled_for).collect {|day| day.scheduled_for }
    @premises = {}
    Premise.find(:all, :order => "name ASC").each do |e|
      @premises[e.id] = e.name
    end
    @meal_categories = {}
    MealCategory.find(:all, :order => "name ASC").each do |e|
      @meal_categories[e.id] = e.name
    end
    super
  end
  
  def new
    @options[:form_fields].each {|field|
      field[:data] = field[:data_proc].call if field[:data_proc].is_a?(Proc)
    }
    super
  end
  
  def edit
    @record = RestaurantSale.find_by_id params[:id]
    @options[:form_fields].each {|field|
      if field[:type] == :select
        field[:data] = [@record.send(field[:name])].collect{|d| [ d.name, d.id ] }
        field[:selected] = @record.send(field[:name]).id
      end
    }
    super
  end
  
  def create
    params[:record]["item"] = Item.find_by_item_id(params[:record]["item"])
    params[:record]["premise"] = Premise.find_by_id(params[:record]["premise"])
    super
  end
  
  def update
    params[:record]["item"] = Item.find_by_item_id(params[:record]["item"])
    params[:record]["premise"] = Premise.find_by_id(params[:record]["premise"])
    super
  end
end

