class ViewsController < ApplicationController
  before_filter(:only => [:cooking]) { |c| c.must_belong_to_one_of(:admins, :operating_officers, :warehousers, :chefs)}
  before_filter(:only => [:items_to_load, :shopping_list]) { |c| c.must_belong_to_one_of(:admins, :warehousers, :chefs)}
  before_filter(:only => [:summary]) { |c| c.must_belong_to_one_of(:admins, :operating_officers, :chefs)}
  before_filter(:except => [:summary, :items_to_load, :shopping_list, :cooking]) { |c| c.must_belong_to_one_of(:admins, :chefs)}
  include_javascripts 'calendar_widget', 'fullscreen'
  include_stylesheets 'jquery-ui'
  include FilterWidget
  
  def average_day
    @selected_dates = CalendarWidget.parse params[:date]
    @summary = Summary.average_day(@selected_dates[0], @selected_dates[1])
    @expenses = {:delivery => [],  :restaurant => [], :office => []}
    ExpenseCategory.average_by_day(@selected_dates[0],  @selected_dates[1]).each{|e| @expenses[e[:expense_owner].to_sym].push e }
    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }
    respond_to do |format|
      format.js do 
        render :update do  |page|
          page.replace "summary", :partial => "summary"
        end
      end
      format.html
    end
  end
  
  def summary
    @selected_dates = CalendarWidget.parse params[:date]
    @summary = Summary.between(@selected_dates[0], @selected_dates[1])
    @expenses = {:delivery => [],  :restaurant => [], :office => []}
    ExpenseCategory.by_day(@selected_dates[0],  @selected_dates[1]).each{|e| @expenses[e[:expense_owner].to_sym].push e }

    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }
    respond_to do |format|
      format.js do 
        render :update do  |page|
          page.replace "summary", :partial => "summary"
        end
      end
      format.html
    end
  end
  
  def items_to_load
    dates = CalendarWidget.parse params[:date]
    
    @dates = Day.find(:all, :order => :scheduled_for).collect {|day| day.scheduled_for }
    items_to_load = ItemToLoad.find :all, :from => "total_assigned_ordered_meals_for('#{dates.first.to_s}')", :include => [:item, :user]
    @delivery_men = {}
    @items = {}
    items_to_load.each {|itl|
      next if itl.item_id.nil? #TODO: ughly workaround to ignore products from eshop
      @delivery_men[itl.user] ||= {}
      @delivery_men[itl.user][itl.item_id] = itl
      @items[itl.item_id] ||= {:item => itl.item, :amount => 0}
      @items[itl.item_id][:amount] += itl.amount
    }
    respond_to do |format|
      format.js do 
        render :update do  |page|
          page.replace "items_to_load", :partial => "items_to_load"
        end
      end
      format.html
    end
  end
  
  def shopping_list
    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }
    
    dates = CalendarWidget.parse params[:date]
    conditions = filter_widget_conditions(params[:filter]) if params[:filter].is_a?(Array)
    @list = ShoppingList.between(dates[0], dates[1], :conditions => conditions, :order => params[:order] )
    @total_cost = ShoppingList.sum_between(dates[0], dates[1], :conditions => conditions)
    suppliers = Supplier.find_by_sql "SELECT name_abbr, name FROM suppliers"
    @suppliers = {}
    suppliers.each do |e|
      @suppliers[e.name_abbr] = e.name
    end
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'shopping_list', :partial => 'shopping_list'
          page << "update_submit_urls('#{url_for(params.merge({'date' => '__date__'})).sub('&amp;', '&')}', '#{url_for(params.delete_if {|key,val| key == 'filter'}).sub('&amp;', '&')}');"
        end
      end
      format.html do
        render
      end
    end
  end
  
  def stock
    dates = CalendarWidget.parse params[:date]
    
    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }
    @list = Stock.find :all, :order => 'scheduled_for', :conditions => "scheduled_for BETWEEN '#{dates[0].to_s}' AND '#{dates[1].to_s}'"
    
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'stock', :partial => 'stock'
          #page << "update_submit_urls('#{url_for(params.merge({'date' => '__date__'})).sub('&amp;', '&')}', '#{url_for(params.delete_if {|key,val| key == 'filter'}).sub('&amp;', '&')}');"
        end
      end
      format.html do
        render
      end
    end
  end
  
  def cooking
    dates = CalendarWidget.parse params[:date]
    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }
    scheduled = ScheduledItem.find :all, :order => 'scheduled_for, table_name DESC', :conditions => "scheduled_for BETWEEN '#{dates[0].to_s}' AND '#{dates[1].to_s}'", :joins => "LEFT JOIN item_tables_view ON item_tables_view.item_id = scheduled_items_view.item_id", :select => "scheduled_items_view.*, item_tables_view.table_name as table_name"
    @ingredients = ShoppingList.between(dates[0], dates[1], :order => "supply_flag ASC, name ASC" )
    @scheduled_items = {}
    scheduled.each { |s|
      unless @scheduled_items[s.item_id]
        @scheduled_items[s.item_id] = s
      else
        @scheduled_items[s.item_id][:amount] += s[:amount]
      end
    }
    scheduled.clear
    menu_hash = {}
    menu_ids = []
    @scheduled_items.each_pair { |k,i|
       menu_ids.push k if i[:table_name].singularize == "menu"
    }
    unless menu_ids.empty?
      menus = Menu.find :all, :include=> [:meals], :conditions => "menus.item_id IN (#{menu_ids.join(',')})"
    else
      menus = []
    end
    
    for menu in menus
      arr = []
      meals = menu.meals
      for meal in meals
        arr.push @scheduled_items.delete(meal.item_id)
      end
      menu_hash[@scheduled_items[menu.item_id]] = arr unless arr.empty?
    end
    @scheduled_items.each_pair { |k,v|
      if menu_hash.has_key? v
        @scheduled_items.delete k
      end
    }
    
    @scheduled_menus = menu_hash
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'cooking', :partial => 'cooking'
        end
      end
      format.html do
        render
      end
    end    
  end
end
