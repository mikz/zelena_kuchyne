# -*- encoding : utf-8 -*-
class OrdersController < ApplicationController
  before_filter(:except => [:mine, :show]) { |c| c.must_belong_to_one_of(:admins)}
  before_filter :login_required, :only => :mine
  before_filter :find_delivery_men, :except => :mine
  before_filter :load_sidebar_content, :only => :mine
  before_filter :load_zones, :only => [:edit, :update, :add_item, :remove_item, :index, :set_user_zone]
  active_section 'orders'
  
  include FilterWidget
  include_javascripts 'calendar_widget', 'orders', 'scheduled_items', "fullscreen" , :except => [:mine]
  include_stylesheets 'jquery-ui', :except => [:mine]
  
  def index
    conditions = "state != 'basket'"
    dates = CalendarWidget.parse params[:date]
    conditions << " AND CAST(deliver_at AS date) BETWEEN '#{dates.first.to_s}' AND '#{dates.last.to_s}'"
    
    cancelled = params[:state] == 'cancelled'
    state = ((params[:state].nil? or params[:state].empty?) ? "order" : params[:state])
    
    unless state == 'all_cancelled'
      state = false if cancelled
      state = (state == 'all') ? false : state
    
      if state
        conditions << %{ AND cancelled = '#{cancelled}'#{" AND state = #{Order.quote_value(state)}" if state}}
      else
        conditions << " AND cancelled = '#{cancelled}'"
      end
    end
    
    conditions << " AND #{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    
    # Now we have all the conditions, let's actually do something useful
    @orders = OrderView.find :all, :conditions => conditions, :order => 'orders_view.deliver_at ASC, orders_view.updated_at ASC', :include => [{:user => [:addresses, :user_discounts, :user_profiles ]},  :delivery_man]
    @days = Order.days
    if params[:sum]
      @orders_sum = OrderView.find :all, :select => " user_id, MIN(deliver_at)::date AS since, MAX(deliver_at)::date AS to, SUM(price) AS price",:conditions => conditions, :group => "user_id", :include => :user
    end
    # and give it to someone
    
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'orders', :partial => 'orders'
          page << "update_submit_urls('#{url_for(params.merge({'state' => '__state__'})).sub('&amp;', '&')}', '#{url_for(params.merge({'date' => '__date__'})).sub('&amp;', '&')}', '#{url_for(params.delete_if {|key,val| key == 'filter'}).sub('&amp;', '&')}');"
          page << "init_draggable_orders(); init_address_helpers();"
        end
      end
      format.html do
        render
      end
      format.xls do
        send_data @orders.to_xls(:only => [], :methods => [:id, 'user.delivery_address.output', 'user.delivery_address.zone.name', 'order.delivery_man.name', :cancelled?, :deliver_at]), :filename => "orders.xls"
      end
    end
  end
  
  def show
    @order = OrderView.find params[:id], :include => [{:user=>:user_discounts}, {:ordered_items => :item}]
    unless @order.user_id == current_user.id
      must_belong_to_one_of(:admins, :chefs, :sales, :delivery_men)
    end
    @print = (params[:print])
  end
  
  def edit
    show
    @meals = Meal.find :all, :order => "name ASC"
    @menus = Menu.find :all, :order => "name ASC"
    @bundles = Bundle.find :all, :order => "name ASC"
  end
  
  def mine
    @orders = OrderView.mine.find(:all,
                             :conditions => "orders_view.user_id = #{current_user.id} AND state != 'basket'",
                             :include => [{:user => :addresses}],
                             :order => params[:order]).paginate(:page => params[:page], :per_page => 15)
  end
  
  def assign
    @order = Order.find params[:id]
    
    Order.transaction do
      if params[:delivery_man_id].present?  # clients sends "null", bleeeah
        @order.set_delivery_man_id params[:delivery_man_id].to_i
      else
        @order.delivery_man_id = nil
      end
    
      @order.save_without_validation!
    end
    
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "order_#{@order.id}", :partial => 'order', :locals => {:order => @order.order_view, :delivery_men => @delivery_men}
          page.visual_effect :highlight, "order_#{@order.id}"
        end
      end
    end
  end
  
  
  def change_state
    @order = Order.find params[:id]

    @order.update_attribute :state, params[:state]
  
    respond_to do |format|
      format.js do
        render :update do |page|
          page.visual_effect :fade, "#orders .orders-with-state #order_#{@order.id}"
          page.delay 0.3 do
            page.remove "#orders .orders-with-state #order_#{@order.id}"
            page.visual_effect :highlight, "order-tab-#{@order.state}", :duration => 0.5
          end
        end
      end
    end
  end
  
  def toggle_cancelled
    @order = Order.find params[:id]
    
    @order.update_attribute :cancelled, !@order.cancelled
    
    respond_to do |format|
      format.js do
        render :update do |page|
          page.visual_effect :fade, "order_#{@order.id}"
          page.delay 0.3 do
            page.remove "order_#{@order.id}"
            if @order.cancelled
              page.visual_effect :highlight, "order-tab-cancelled", :duration => 0.5
            else
              page.visual_effect :highlight, "order-tab-#{@order.state}", :duration => 0.5
            end
          end
        end
      end
    end
  end

  def active_discounts
    @order = OrderView.find params[:id]
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html "active_discounts", :partial => "active_discounts"
          page.visual_effect :highlight, "active_discounts", :duration => 0.5
        end
      end
    end
  end
  
  def set_deliver_at
    @order = Order.find params[:id]
    @order.deliver_at = Time.parse("#{params[:deliver_at][:date]} #{params[:deliver_at][:time]}")

    respond_to do |format|
      format.js {
        if  @order.save_without_validation
          render :update do |page|
            page << "ajax_message(#{t(:update_successful).mb_chars.capitalize.to_s.inspect});"
            if @order.ordered_items.empty?
              page.visual_effect :fade, "text .order .ordered_item"
              page.delay 0.3 do 
                page.remove "text .order .ordered_item"
              end
              page.replace_html 'order-total', format_currency(0)
              page.visual_effect :highlight, 'order-total'
            end
            page.visual_effect :highlight, 'deliver_at_form'
            page << "update_active_discounts(#{params[:id]})"
          end
        else
          render :update do |page|
            page << "ajax_message(#{t(:error).mb_chars.capitalize.to_s.inspect});"
          end
        end
      }
    end
  end
  
  def merge
    @order = Order.find params[:dropped]
    @other_order = Order.find(params[:dragged])
    
    respond_to do |format|
      if @order.merge @other_order
        format.js
        format.html {
          redirect_to :action => :index
        }
      else
        message = "Objednávky č.#{@order.id} a #{@other_order.id} nelze spojit."
        format.js {
          render :update do |page|
            page << "ajax_message(#{message.inspect});"
          end
        }
        format.html {
          flash[:notice] = message
          redirect_to :action => :index
        }
      end
    end
  end
  
  def add_item
    return unless @order = Order.find(params[:id])
    begin
      item = OrderedItem.find_by_order_id_and_item_id(params[:id], params[:item_id])
      ordered_items = @order.ordered_items.clone
      if item
        item.amount += 1
        item.save
      else
        item = @order.ordered_items.create({:item_id => params[:item_id], :amount => 1})
      end
      
      @order = OrderView.find(params[:id],:include=>[:ordered_items])
      
      respond_to do |format|
        format.js do
          render :update do |page|
            page.replace_html "record_#{params[:id]}", :partial => "form"
            page.visual_effect :highlight, "record_#{params[:id]}"
            page << "update_active_discounts(#{params[:id]})"
          end
        end
      end
      
    rescue Exception => e
      raise e
      respond_to do |format|
        format.js do
          render :update do |page|
            page << "ajax_message(#{t(:error).mb_chars.capitalize.to_s.inspect});"
            page.visual_effect :Shake, 'add_item_form', :times => 2
          end
        end
      end
    end
  end
  
  def remove_item
    OrderedItem.delete(params[:item_id])
    order = OrderView.find(params[:id])
    
    respond_to do |format|
      format.html do
        redirect_to :back
      end
      format.js do
        render :update do |page|
          page.visual_effect :fade, "item_#{params[:item_id]}"
          page.replace_html 'order-total', format_currency(order.price)
          page.visual_effect :highlight, "order-total"
          page.delay 0.3 do
            page.remove "item_#{params[:item_id]}"
          end
          page << "update_active_discounts(#{params[:id]})"
        end
      end
    end
  end
  
  def update
    @order = Order.find(params[:id],:include => [{:ordered_items => :item}])
    @order.delivery_method_id = params[:delivery_method_id]
    @order.delivery_method_id_will_change!
    
    if @order.save_without_validation
        items = @order.ordered_items.clone # don't ask how, but this gets ordered items before update. See below
        unless items.empty?
        @order.update_items(params['amount'])
    
        @order = OrderView.find params[:id], :include => [{:ordered_items => :item}]
    
        respond_to do |format|
          format.html do
            flash[:notice] = t(:order_updated)
            redirect_to :back
          end
          format.js do
            render :update do |page|
              page << "ajax_message(#{t(:update_successful).mb_chars.capitalize.to_s.inspect});"
              page.replace_html "record_#{params[:id]}", :partial => "form"
              page.visual_effect :highlight, "record_#{params[:id]}"
              page << "update_active_discounts(#{params[:id]})"
            end
          end
        end
      else
        respond_to do |format|
          format.html do
            flash[:notice] = t(:order_updated)
            redirect_to :back
          end
          format.js do
            render :update do |page|
              page << "ajax_message(#{t(:update_successful).mb_chars.capitalize.to_s.inspect});"
              page.replace_html 'order-total', format_currency(0)
              page.visual_effect :highlight, "order-total"
            end
          end
        end
      end
    else
      respond_to do |format|
        format.js do
          render :update do |page|
            page << "ajax_message(#{t(:error).mb_chars.capitalize.to_s.inspect});"
          end
        end
      end
    end
  end
  
  def set_notice
    @order = Order.find(params[:id])
    respond_to do |format|
      format.js {
        if @order.update_attribute :notice, params[:order][:notice]
          render :update do |page|
            page.visual_effect :highlight, "notice_form"
          end
        else
          render :update do |page|
            page << "ajax_message(#{t(:error).mb_chars.capitalize.to_s.inspect});"
          end
        end
      }
    end
    
  end
  
  private
  
  def find_delivery_men
     @delivery_men = DeliveryMan.find :all
  end
  
  protected
  def load_sidebar_content
    @polls ||= Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
    @news ||= News.valid_news :order => 'publish_at DESC, id DESC', :limit => 5
    @days ||= Day.find :all
    @date ||= params[:id] ? Date.parse(params[:id]) : Date.today
    
    @dialy_menu, @dialy_entries, @dialy_categories = load_dialy_menu
  end
  def load_zones
    @zones = Zone.find :all, :order => "name ASC", :include => [:delivery_methods]
  end
end

