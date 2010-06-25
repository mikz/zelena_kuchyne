class ScheduleController < ApplicationController
  before_filter(:only => [:index, :agenda]) { |c| c.must_belong_to_one_of(:admins, :warehousers, :operating_officers, :deliverymen, :chefs)}
  before_filter(:except => [:index, :agenda]) { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'calendar_widget'
  include_stylesheets 'jquery-ui'

  def index
    agenda
  end

  def new
    @meals = Meal.find :all, :order => "name ASC", :conditions => ["restaurant_flag = false"]
    @menus = Menu.find :all, :order => "name ASC"
    @bundles = Bundle.find :all, :order => "name ASC"
    respond_to do |format|
      format.js do
        render :update do |page|
          page.insert_html :top, "records_body", :partial=> 'new', :locals => {:date => params[:date]}
          page.hide 'record_add'
          page << 'init();'
        end
      end
      format.html
    end
  end

  def edit
    @meals = []
    @bundles = []
    @menus = []
    if params[:what] == "menu"
      @scheduled = ScheduledMenu.find_by_oid params[:id]
      @menus = [Menu.find_by_id(@scheduled.menu_id)]
    elsif params[:what] == "meal"
      @scheduled = ScheduledMeal.find_by_oid params[:id]
      @meals = [Meal.find_by_id(@scheduled.meal_id)]
    elsif params[:what] == "bundle"
      @scheduled = ScheduledBundle.find_by_oid params[:id]
      @bundles = [Bundle.find_by_id(@scheduled.bundle_id)]
    end

    respond_to do |format|
      format.js do
        render :update do |page|
          element = "record_#{params[:what]}_#{@scheduled.oid}"
          page.insert_html :after, element, :partial => 'edit', :locals => {:scheduled => @scheduled, :what => params[:what], :element => element, :date => params[:date]}
          page.hide element
          page.select(".#{element}").hide()
          page << 'init();'
        end
      end
    end
  end

  def agenda
    dates = CalendarWidget.parse params[:id]
    if dates == [Date.today,Date.today]
      @days = Day.find :all, :invisible => true, :conditions => "days_view.scheduled_for = '#{Date.today.to_s}'", :include => [{:scheduled_meals => :meal},{:stock=>:meal},{:scheduled_menus => {:menu =>:meals}},{:scheduled_bundles => :bundle}]
    else
      @days = Day.find :all, :invisible => true, :conditions => "days_view.scheduled_for BETWEEN '#{dates[0].to_s}' AND '#{dates[1].to_s}'", :include => [{:scheduled_meals => :meal},{:stock=>:meal},{:scheduled_menus => {:menu =>:meals}},{:scheduled_bundles => :bundle}]
    end


    @dates = Day.find(:all, :invisible => true).collect {|day| day.scheduled_for }

    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace 'agenda', :partial => 'agenda'
        end
      end
      format.html do
        render :action => 'agenda'
      end
      format.json do
        render :text => @days.to_json(
          :include => {
            :scheduled_meals => {
              :only => [:amount],
              :include => {
                :meal => { :only => [:name, :item_id] }
              }
            },
            :scheduled_menus => {
              :only => [:amount],
              :include => {
                :menu => {
                  :only => [:item_id, :name],
                  :include => {
                    :meals => { :only => [:name, :item_id]  }
                  }
                }
              }
            },
            :scheduled_bundles => {
              :only => [],
              :include => {
                :bundle => { :only => [:name, :item_id] }
              }
            }
          }
      )
      end
    end
  end

  def deschedule_menu
    date = Date.parse(params[:date] || params[:schedule]['date'])
    ScheduledMenu.delete_all ["menu_id = ? AND scheduled_for = ?", params[:id].to_i, date]
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js do
        render :update do |page|
          page << "window.location = '#{request.referer}'"
        end
      end
    end
  end

  def deschedule_bundle
    date = Date.parse(params[:date] || params[:schedule]['date'])
    ScheduledBundle.delete_all ["bundle_id = ? AND scheduled_for = ?", params[:id].to_i, date]
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js do
        render :update do |page|
          page << "window.location = '#{request.referer}'"
        end
      end
    end
  end

  def deschedule_meal
    date = Date.parse(params[:date] || params[:schedule]['date'])
    ScheduledMeal.delete_all ["meal_id = ? AND scheduled_for = ?", params[:id].to_i, date]
    ScheduledBundle.delete_all(["bundle_id IN(?) AND scheduled_for = ?", Bundle.find(:all,:conditions => ["meal_id = ?", params[:id].to_i]).map {|b| b.id}, date])
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js do
        render :update do |page|
          page << "window.location = '#{request.referer}'"
        end
      end
    end
  end

  def schedule_item
    item = (params[:schedule]['item_id'] || params[:what]).split(':')
    date = Date.parse params[:schedule]['date']
    case item[0]
    when 'meal'
      if params[:id]
        meal = ScheduledMeal.find :first, :conditions => ["oid = ?", params[:id].to_i]
      else
        meal = ScheduledMeal.find :first, :conditions => ["scheduled_for = ? AND meal_id = ?", date, item[1].to_i ]
      end
      if meal
        if params[:schedule]['amount'].to_i <= 0
          ScheduledMeal.delete_all ["oid = ?", meal.oid]
          ScheduledBundle.delete_all(["bundle_id IN(?) AND scheduled_for = ?", Bundle.find(:all,:conditions => ["meal_id = ?", meal.meal_id]).map { |b| b.id}, meal.scheduled_for])
        else
          meal.amount = params[:schedule]['amount'].to_i
          ScheduledMeal.update_all "amount = '#{params[:schedule]['amount'].to_i}', invisible = #{params[:schedule]['invisible'].to_i == 1}", ["oid = ?", meal.oid]
        end
      elsif params[:schedule]['amount'].to_i > 0
        ScheduledMeal.create(:meal_id => item[1].to_i, :amount => params[:schedule]['amount'].to_i, :scheduled_for => date, :invisible => params[:schedule]['invisible'].to_i)
      end
    when 'bundle'
      if params[:id]
        scheduled_bundle = ScheduledBundle.find(:first, :conditions => ["oid = ?", params[:id]], :include => [:bundle])
        scheduled_meal = ScheduledMeal.find(:first,:conditions => ["scheduled_for = ? AND meal_id = ?", scheduled_bundle.scheduled_for, scheduled_bundle.bundle.meal_id])
        if params[:schedule]['amount'].to_i <= 0
          ScheduledBundle.delete_all ["oid = ?", params[:id].to_i]
        else
          ScheduledMeal.update_all "amount = '#{params[:schedule]['amount'].to_i*scheduled_bundle.bundle.amount}', invisible = #{params[:schedule]['invisible'].to_i == 1}", ["oid = ?", scheduled_meal.oid]
        end
      else
        bundle = Bundle.find_by_id item[1].to_i
        scheduled_bundle = ScheduledBundle.find :first, :conditions => ["scheduled_for = ? AND bundle_id = ?", date, item[1].to_i]
        unless scheduled_bundle
          scheduled_bundle = ScheduledBundle.create(:bundle_id => bundle.id, :amount => params[:schedule]['amount'].to_i, :scheduled_for => date, :invisible => params[:schedule]['invisible'].to_i)
        end
      end
    when 'menu'
      if params[:id]
        menu = ScheduledMenu.find :first, :conditions => ["oid = ?", params[:id].to_i]
      else
        menu = ScheduledMenu.find :first, :conditions => ["scheduled_for = ? AND menu_id = ?", date, item[1].to_i ]
      end
      if menu
        if params[:schedule]['amount'].to_i <= 0
          ScheduledMenu.delete_all ["oid = ?", menu.oid]
        else
          ScheduledMenu.update_all "amount = '#{params[:schedule]['amount'].to_i}', invisible = #{params[:schedule]['invisible'].to_i == 1}", ["oid = ?", menu.oid]
        end
      else
        ScheduledMenu.create(:menu_id => item[1].to_i, :amount => params[:schedule]['amount'].to_i, :scheduled_for => date, :invisible => params[:schedule]['invisible'].to_i )
      end
    end
    respond_to do |format|
      format.html do
        redirect :back
      end
      format.js do
        render :update do |page|
          page << "window.location = '#{url_for(:controller=>"schedule",:id=>date)}';"
        end
      end
    end
  end
end
