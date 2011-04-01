class MenuController < ApplicationController
  active_section 'menu'
  include_javascripts "menu"
  before_filter :load_sidebar_content, :except => [:feed]
  
  def index
    @date = params[:id] ? Date.parse(params[:id]) : Date.today
    
    redirect_to  menu_path(@date), :status => :temporary_redirect
  end
  
  
  def print
    @days = Day.find(:all, :conditions => ["scheduled_for >= ?", Date.today]).collect &:scheduled_for
    
    @selected = []

    if params[:selected] && params[:selected][:days]
      @selected = params[:selected][:days].collect{|d| Date.parse(d) }
    end
    
    respond_to do |format|
      format.html {

      }
      format.print {
        load_all_scheduled_for ["scheduled_for IN (?)", @selected]
      }
      
    end
  end
  
  def show
    @days = Day.find :all, :conditions => ["scheduled_for >= ?", Date.today]
    @date = params[:id] ? Date.parse(params[:id]) : Date.today
    
    @menus = Menu.find :all, :include => [:scheduled_menus, {:meals => {:meal_category => :order}}], :conditions => ["scheduled_menus.scheduled_for = ? AND scheduled_menus.invisible = false", @date], :order => "meal_category_order.order_id ASC"
    
    @categories = MealCategory.find :all, :include => [{:meals => [:scheduled_meals, :item_profiles, :item_discounts, :meal_flags]}, :order], :conditions => ["meals.always_available = true OR scheduled_meals.scheduled_for = ? AND scheduled_meals.invisible = false AND meals.id NOT IN (?)", @date, @menus.map{|m| m.meals.map(&:id)}.flatten.uniq], :order => "meal_category_order.order_id ASC"
    @scheduled_bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for = ? AND scheduled_bundles.invisible = false", @date], :include => [{:bundle => {:meal => :meal_category}}]
    
    
    ids = []
    scheduled = {:meals => [], :menus => []}
    
    @menus.each do |menu|
      scheduled[:menus] << menu
      menu.meals.each do |meal|
        ids << meal.id
      end
    end
    @categories.each do |category|
      category.meals.each do |meal|
        scheduled[:meals] << meal unless meal.always_available?
        ids << meal.id
      end
    end
    
    @sold_out = {}
    Stock.find(:all, :conditions => ["meal_id IN (?) AND scheduled_for = ? AND amount_left <= 0", ids, @date]).each { |stock|
      @sold_out[stock.meal_id] = stock
    }
    
    @delivery = Order.delivery_times(@date, Time.now)
    
    DEBUG {%w{scheduled}}
    
    respond_to do |format|
      if @date < Date.today
        format.html { render 'unavailable', :status => :unprocessable_entity }
        format.json { render :json => nil, :status => :unprocessable_entity }
      else
        if @scheduled_bundles.empty? && scheduled[:meals].empty? && scheduled[:menus].empty?
          format.html { render 'no_scheduled_meals' }
          format.json { render :json => nil, :status => :not_found }
        else
          format.html { render 'show' }
          format.json {
            @scheduled = scheduled
            render
          }
        end
      end
    end
  end
  
  def feed
    load_all_scheduled_for 
    
    respond_to do |format|
      format.xml
    end
  end
  
  protected
  def load_sidebar_content
    @polls ||= Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
    @news ||= News.valid_news :order => 'publish_at DESC, id DESC', :limit => 5
    @days ||= Day.find :all, :conditions => ["scheduled_for >= ?", Date.today]
    @date ||= params[:id] ? Date.parse(params[:id]) : Date.today
    
    @dialy_menu, @dialy_entries, @dialy_categories = load_dialy_menu
  end
  
  def load_all_scheduled_for conditions = ["scheduled_for >= ?", Date.today], expand_menus = false
    @scheduled_items = ActiveSupport::OrderedHash.new
    @days = Day.find(:all, :conditions => conditions, :order => "scheduled_for").each do |day|
      @scheduled_items[day.scheduled_for] = {:categories => ActiveSupport::OrderedHash.new, :menus => []}
    end
    dates = @days.collect &:scheduled_for
    
    @menus = Menu.find :all, :include => [:scheduled_menus, {:meals => {:meal_category => :order}}], :conditions => ["scheduled_menus.scheduled_for IN (?) AND scheduled_menus.invisible = false", dates], :order => "meal_category_order.order_id ASC"
    
    filter_meals = {}
    @menus.each do |menu|
      menu.scheduled_menus.each do |sm|
        filter_meals[sm.scheduled_for] ||= []
        filter_meals[sm.scheduled_for].push *sm.menu.meals.map(&:id).flatten.uniq
      end
    end
    
    days = filter_meals.keys.size
    menu_meals_filter = days.times.collect {
      "(scheduled_meals.scheduled_for = ? AND meals.id NOT IN (?))"
    }.join(" OR ")
    categories_conditions = ["scheduled_meals.scheduled_for IN (?) AND scheduled_meals.invisible = false AND (#{menu_meals_filter})", dates]
    filter_meals.each_pair{ |date, days|
       categories_conditions.push date, days
    }
    @categories = MealCategory.find :all, :include => [{:meals => :scheduled_meals}, :order], :conditions => categories_conditions, :order => "meal_category_order.order_id ASC"
    @scheduled_bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for IN (?) AND scheduled_bundles.invisible = false", dates], :include => [{:bundle => {:meal => :meal_category}}]

    @categories.each do |category|
      category.meals.each do |meal|
        meal.scheduled_meals.each do |scheduled|
          @scheduled_items[scheduled.scheduled_for][:categories][category] ||= []
          @scheduled_items[scheduled.scheduled_for][:categories][category] << meal
        end
      end
    end
    
    @menus.each do |menu|
      menu.scheduled_menus.each do |scheduled|
        @scheduled_items[scheduled.scheduled_for][:menus] << menu
      end
    end
    
    @scheduled_bundles.each do |scheduled|
      @scheduled_items[scheduled.scheduled_for][:categories][scheduled.bundle.meal.meal_category] << scheduled.bundle
    end
  end
end
