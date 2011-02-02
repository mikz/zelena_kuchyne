class MassMenuController < ApplicationController
  active_section 'menu'
  include_javascripts "menu"
  
  def index
    @days = Day.find(:all, :conditions => ["scheduled_for >= ?", Date.today]).collect &:scheduled_for
    load_all_scheduled_for ["scheduled_for IN (?)", @days]
    @delivery = {}
    @dates.each do |date|
      @delivery[date] = Order.delivery_times(date, Time.now, current_user)
    end
    DEBUG {%w{@delivery}}
    respond_to do |format|
      format.html
    end
  end
  
  def create
    load_orders
    
    Order.transaction do
      params[:mass_menu].each_pair do |date, params|
        o = Order.create(:deliver_at => date, :state => 'validating', :user => current_user)
        o.time_of_delivery = params.delete('time_of_delivery')
        o.update_or_insert_items params
        o.save
        o.reload
        @orders << o.order_view
        o.destroy if o.ordered_items.blank?
      end if @orders.blank?
      
      respond_to do |format|
        format.html
      end
      
      session[:mass_menu] = @orders.collect &:id
    end
  end
  
  
  def confirm
    load_orders
    @orders.each do |view|
      
      view.order.state = 'order'
      view.order.save
      view.reload
      begin
        Mailer.deliver_order_submitted(current_user, view)
      rescue
        logger.error %{
          Sending mail failed with error: #{$!.to_s}
          Params: #{params.inspect}
          Trace: #{$!.backtrace.join("\n\t\t")}
        }
      end
    end
    
    flash[:notice] = locales[:order_submitted].chars.capitalize
    
    redirect_to "/"
  end
  
protected
  def load_orders
    @orders = []
    unless session[:mass_menu].blank?
      @orders = Order.find(:all, :conditions => ["id IN (?)", session[:mass_menu]]).map(&:order_view)
    end
  end
  
  def load_all_scheduled_for conditions = ["scheduled_for >= ?", Date.today], expand_menus = false
    @scheduled_items = ActiveSupport::OrderedHash.new
    @days = Day.find(:all, :conditions => conditions, :order => "scheduled_for").each do |day|
      @scheduled_items[day.scheduled_for] = {:categories => ActiveSupport::OrderedHash.new, :menus => []}
    end
    @dates = @days.collect &:scheduled_for
    
    @menus = Menu.find :all, :include => [:scheduled_menus, {:meals => {:meal_category => :order}}], :conditions => ["scheduled_menus.scheduled_for IN (?) AND scheduled_menus.invisible = false", @dates], :order => "meal_category_order.order_id ASC"
    
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
    categories_conditions = ["scheduled_meals.scheduled_for IN (?) AND scheduled_meals.invisible = false AND (#{menu_meals_filter})", @dates]
    filter_meals.each_pair{ |date, days|
       categories_conditions.push date, days
    }
    
    @categories = MealCategory.find :all, :include => [{:meals => :scheduled_meals}, :order], :conditions => categories_conditions, :order => "meal_category_order.order_id ASC"
    @bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for IN (?) AND scheduled_bundles.invisible = false", @dates], :include => [{:bundle => {:meal => :meal_category}}]
    
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
    
    @bundles.each do |scheduled|
      @scheduled_items[scheduled.scheduled_for][:categories][scheduled.bundle.meal.meal_category] << scheduled.bundle
    end
  end
end