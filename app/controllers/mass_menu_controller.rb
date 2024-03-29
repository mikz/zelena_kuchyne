# -*- encoding : utf-8 -*-
class MassMenuController < ApplicationController
  active_section 'menu'
  include_javascripts "menu"

  before_filter :login_required

  def show
    @days = Day.find(:all, :conditions => ["scheduled_for >= ?", Date.today]).collect &:scheduled_for
    return render('menu/no_scheduled_meals') unless @days.present?

    load_all_scheduled_for ["scheduled_for IN (?)", @days]
    @delivery = {}
    @dates.each do |date|
      @delivery[date] = Order.delivery_times(date, Time.now, current_user)
    end

    @mass_menu = session[:mass_menu] || MassMenu.new(Hash[@scheduled_items.map{|k,v|[k.to_s,'']}])
    
    load_orders(false).each &:destroy
    
    respond_to do |format|
      format.html
    end
  end
  
  def update
    
    session[:mass_menu] = MassMenu.new params[:mass_menu]
    unless params[:mass_menu].delete(:confirmation) || current_user.admin?
      return redirect_to(:back, :notice => t(:have_to_accept_agreement))
    end
    
    @user = current_user
    if current_user.admin? && params[:order].present? && params[:order][:user]
      @user = User.find_by_login!(params[:order][:user])
      session[:order_user] = params[:order][:user]
    end
    
    load_orders(false)

    to_destroy = []
    Order.transaction do
      params[:mass_menu].each_pair do |date, params|
        
        o = Order.create(:deliver_at => date, :state => 'validating', :user => @user, :time_of_delivery => params.delete(:time_of_delivery))
        o.update_or_insert_items params
        
        if !o.valid_without_callbacks? && o.errors.on(:ordered_items)
          o.fix_amounts
          o.save
        end

        o.reload
        @orders << o
        to_destroy << o if o.ordered_items.blank?
        
      end if @orders.empty?
      
      respond_to do |format|
        format.html
      end
      
      to_destroy.each &:destroy
      session[:mass_menu_orders] = @orders.collect &:id
    end
  end
  
  
  def create
    load_orders(false)
    @orders.each do |order|
      
      order.state = 'order'
      order.save
      
      begin
        Mailer.deliver_order_submitted(current_user, order.view)
      rescue
        logger.error %{
          Sending mail failed with error: #{$!.to_s}
          Params: #{params.inspect}
          Trace: #{$!.backtrace.join("\n\t\t")}
        }
      end
    end
    
    session[:mass_menu_orders] = session[:mass_menu] = session[:order_user] = nil
    flash[:notice] = t(:orders_submitted).mb_chars.capitalize
    
    redirect_to "/"
  end
  
protected
  def load_orders(views = true)
    @orders = []
    unless session[:mass_menu_orders].blank?
      @orders = Order.find(:all, :conditions => ["id IN (?) AND state = ?", session[:mass_menu_orders], 'validating'])
      @orders = @orders.map(&:order_view) if views
    end
    @orders
  end
  
  def load_all_scheduled_for conditions = ["scheduled_for >= ?", Date.today], expand_menus = false
    @scheduled_items = ActiveSupport::OrderedHash.new
    @days = Day.find(:all, :conditions => conditions, :order => "scheduled_for").each do |day|
      @scheduled_items[day.scheduled_for] = {:categories => ActiveSupport::OrderedHash.new, :menus => []}
    end
    @dates = @days.collect &:scheduled_for
    
    @menus = Menu.find :all, :include => [{:scheduled_menus => {:menu => [:item_profiles, :item_discounts]}}, :item_profiles, :item_discounts, {:meals => [{:meal_category => :order}, :meal_flags, :item_profiles, :item_discounts]}], :conditions => ["scheduled_menus.scheduled_for IN (?) AND scheduled_menus.invisible = false", @dates], :order => "meal_category_order.order_id ASC"

    ids = []
    filter_meals = Hash[ @dates.zip(@dates.length.times.map{[]}) ]

    @menus.each do |menu|
      menu.scheduled_menus.each do |scheduled|
        filter_meals[scheduled.scheduled_for].push *menu.meals.map(&:id).flatten.uniq
        @scheduled_items[scheduled.scheduled_for][:menus] << menu
      end
    end
    
    ids << filter_meals.values
    
    days = filter_meals.keys.size
    menu_meals_filter = days.times.collect {
      "(scheduled_meals.scheduled_for = ? AND meals.id NOT IN (?))"
    }.join(" OR ")
    categories_conditions = ["scheduled_meals.scheduled_for IN (?) AND scheduled_meals.invisible = false AND (#{menu_meals_filter})", @dates]
    filter_meals.each_pair{ |date, days|
       categories_conditions.push date, days
    }
    
    @categories = MealCategory.find :all, :include => [:order, {:meals => [:scheduled_meals, :meal_flags, :item_profiles, :item_discounts]}], :conditions => categories_conditions, :order => "meal_category_order.order_id ASC"
    @bundles = ScheduledBundle.find :all, :conditions => ["scheduled_bundles.scheduled_for IN (?) AND scheduled_bundles.invisible = false", @dates], :include => [{:bundle => {:meal => [:meal_category, :item_profiles, :item_discounts]}}]
    
    @categories.each do |category|
      category.meals.each do |meal|
        meal.scheduled_meals.each do |scheduled|
          @scheduled_items[scheduled.scheduled_for][:categories][category] ||= []
          @scheduled_items[scheduled.scheduled_for][:categories][category] << meal
          filter_meals[scheduled.scheduled_for] << meal.id
        end
      end
    end
    
    @bundles.each do |scheduled|
      @scheduled_items[scheduled.scheduled_for][:categories][scheduled.bundle.meal.meal_category] << scheduled.bundle
    end
    
    @sold_out = Hash[ filter_meals.map{|date, meal_ids|
      [date, Stock.find(:all, :conditions => ["scheduled_for = ? AND meal_id IN (?) AND amount_left <= 0", date, meal_ids]).map(&:meal_id)]
    }]
    
  end
end

