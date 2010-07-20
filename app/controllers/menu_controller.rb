class MenuController < ApplicationController
  active_section 'menu'
  include_javascripts "menu"
  before_filter :load_sidebar_content, :except => [:feed]
  
  def index
    @days ||= Day.find :all, :conditions => ["scheduled_for >= ?", Date.today]
    @date = params[:id] ? Date.parse(params[:id]) : Date.today
    
    show
    @delivery = Order.delivery_times(@date, Time.now)
    if @date < Date.today
      render :action => "unavailable"
    else
      if @categories.size == 0 and @scheduled_bundles.size == 0 and @menus.size == 0
        render :action => "no_scheduled_meals"
      else
        render :action => 'show'
      end
    end
  end
  
  def show
    @categories = MealCategory.find :all, :include => [{:meals => :scheduled_meals}], :conditions => "meals.always_available = true OR scheduled_meals.scheduled_for = '#{@date.to_s}' AND scheduled_meals.invisible = false"
    @scheduled_bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for = ? AND scheduled_bundles.invisible = false", @date.to_s], :include => [{:bundle => {:meal => :meal_category}}]
    @menus = Menu.find :all, :include => [:scheduled_menus, :meals], :conditions => "scheduled_menus.scheduled_for = '#{@date.to_s}' AND scheduled_menus.invisible = false"
    ids = []
    @menus.each do |menu|
      menu.meals.each do |meal|
       ids << meal.id
      end
    end
    @categories.each do |category|
      category.meals.each do |meal|
        ids << meal.id
      end
    end
    @sold_out = {}
    Stock.find(:all, :conditions => ["meal_id IN (?) AND scheduled_for = ? AND amount_left <= 0", ids, @date]).each { |stock|
      @sold_out[stock.meal_id] = stock
    }
  end
  
  def feed
    @scheduled_items = {}
    @days = Day.find(:all, :conditions => ["scheduled_for >= ?", Date.today]).each do |day|
      @scheduled_items[day.scheduled_for] = {:categories => {}, :menus => []}
    end
    
    @categories = MealCategory.find :all, :include => [{:meals => :scheduled_meals}], :conditions => "(meals.always_available = true OR scheduled_meals.scheduled_for >= '#{Date.today.to_s}') AND NOT scheduled_meals.invisible", :order => "scheduled_meals.scheduled_for ASC"
    @menus = Menu.find :all, :include => [:scheduled_menus, :meals], :conditions => "scheduled_menus.scheduled_for >= '#{Date.today.to_s}' AND NOT scheduled_menus.invisible"
    @scheduled_bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for >= ?", Date.today.to_s], :include => [{:bundle => {:meal => :meal_category}}]
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
end