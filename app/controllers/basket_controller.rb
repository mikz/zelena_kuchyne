class BasketController < ApplicationController
  include_javascripts 'basket','jquery.fieldselection'
  include_stylesheets 'time', 'jquery-ui'
  active_section 'basket'
  before_filter :load_sidebar_content, :only => [:index]
  
  def add_item
    begin
      deliver_at = params[:item]['deliver_on'] || Date.parse(( current_user.basket ? current_user.basket.deliver_at : Date.today ).to_s).to_s
      if params[:item]['item_ids'] && params[:item]['amounts']
        @record = OrderedItem.add_to_user :user => current_user, :deliver_at => deliver_at, :item_ids => params[:item]['item_ids'], :amounts => params[:item]['amounts']
      else
        @record = OrderedItem.add_to_user :user => current_user, :deliver_at => deliver_at, :item_id => params[:item]['item_id'], :amount => params[:item]['amount']
      end
      current_user.basket.reload.update_delivery_method(true)
      respond_to do |format|
        format.html do
          flash[:notice] = t(:item_added_to_basket)
          redirect_to :back
        end
        format.js do
          render :update do |page|
            page.remove "notice"
            page.insert_html :top, "text", :partial => "shared/notice", :locals => {:message => t(:item_added_to_basket)}
            page.call "init_notice"
          end
        end
      end
    rescue Order => e
      Rails.logger.error "Error: #{e.inspect} - #{e.backtrace}"
      flash[:notice] = t(:item_cannot_be_added_to_basket)
      respond_to do |format|
        format.html do
          redirect_to :back
        end
        format.js do
          render :update do |page|
            page << "window.location.reload(true);"
          end
        end
      end
    end
  end
  
  def update_order
    @basket = current_user.basket
    @basket.update_items(params['amount'])
    @basket.time_of_delivery = params[:order]['time_of_delivery'] if params[:order]
    msg = nil
    unless current_user.guest?
      if !@basket.valid_without_callbacks? && @basket.errors.on(:ordered_items)
        @basket.fix_amounts
        @basket.save
        msg = t(:we_edited_your_order) + " " + t(:she_had_more_meals_then_we_can_deliver)
      else
        @basket.make_menus_from_meals
      end
    end
    if @basket.order_view
      respond_to do |format|
        format.js do
          render :update do |page|
            @basket.reload
            if msg
              page.remove "notice"
              page.insert_html :top, "text", :partial => "shared/notice", :locals => {:message => msg}
              page.call "init_notice"
            end
            page.replace_html "order", :partial => "order"
            page.visual_effect :highlight, "order", :duration => 0.5
            page << "jQuery('input[name=update]').bind('click', update_basket);"
          end
        end
        format.html do
          flash[:notice] = msg.to_s + t(:order_updated)
          redirect_to :back
        end
      end
    else
      respond_to do |format|
        format.js do
          flash[:notice] = msg
          render :update do |page|
            page << "window.location.reload();"
          end
        end
        format.html do
          flash[:notice] = msg
          redirect_to :action => :index
        end
      end
    end
  end
  
  def index
    @basket = current_user.basket
    unless @basket
      render :action => 'empty_basket'
      return
    end
    @basket.valid?
    @delivery = @basket.delivery_times
  end
  
  def validate_order
    @basket = current_user.basket
    @address = (@basket.user.address[:delivery].nil?) ? @basket.user.address[:home] : @basket.user.address[:delivery]
    unless(logged_in?)
      flash[:notice] = t(:please_sign_up)
      store_location
      redirect_to(:controller => 'users', :action => 'new')
      return
    end
    unless(@address)
      flash[:notice] = t(:please_fill_your_address)
      store_location
      redirect_to(:controller => 'users', :action => 'edit', :id => current_user.id)
      return
    end
    if(params[:validate])
      @basket.update_items(params['amount'])
      @basket.notice = params[:order]['notice']
      @basket.time_of_delivery = params[:order]['time_of_delivery']
      
      if !@basket.save
        if @basket.errors.on(:deliver_at)
          flash[:notice] = t(:deliver_at_time_was_unavailable)
        end
        if @basket.errors.on(:products)
          flash[:notice] = t(:unable_to_deliver_product)
        end
        redirect_to :action => :index
        return
      end
      unless @basket.ordered_items.length > 0
        render :action => "empty_basket"
        return
      end
    end
    @basket = @basket.order_view.reload
    render :action => "validate_order"
  end
  
  def submit
    @basket = current_user.basket
    if params[:update]
      update_order
    elsif params[:validate]
      if current_user.guest?
        flash[:notice] = t(:please_sign_up)
        store_location
        redirect_to(:controller => 'users', :action => 'new')
        return
      elsif (!@basket.valid_without_callbacks? && @basket.errors.on(:ordered_items))
          @basket.fix_amounts
          @basket.save
          flash[:notice] = t(:we_edited_your_order) + " " + t(:she_had_more_meals_then_we_can_deliver)
          redirect_to :action => :index
      elsif  params[:order] and params[:order]['confirmed'] #if everything is ok
        validate_order
      else 
       flash[:notice] = t(:have_to_accept_agreement)
       redirect_to :action => :index
      end
    elsif params[:submit]
      submit_order
    else
      redirect_to :action => :index
    end
    
  end
  
  def submit_order
    @order = current_user.basket
    @order.notice = params[:order]["notice"] if @order
    if(logged_in?)
      if (@order.valid_without_callbacks?)
          flash[:notice] = t(:order_submitted).mb_chars.capitalize
          @order.state = 'order'
          @order.save
          begin
            Mailer.deliver_order_submitted(@order.user, @order.order_view)
          rescue
            logger.error %{
              Sending mail failed with error: #{$!.to_s}
              Params: #{params.inspect}
              Trace: #{$!.backtrace.join("\n\t\t")}
            }
          end
          redirect_to :controller => "/"
      elsif @basket.errors.on(:ordered_items)
        @basket.fix_amounts
        @basket.save
        flash[:notice] = t(:we_edited_your_order) + " " + t(:she_had_more_meals_then_we_can_deliver)
        redirect_to :action => "index"
      elsif @basket.errors.on(:deliver_at)
        flash[:notice] = t(:deliver_at_time_was_unavailable)
        redirect_to :action => "index"
      elsif @basket.errors.on(:products)
        flash[:notice] = t(:errors_on_products)
        redirect_to :action => "index"
      end
    else
      flash[:notice] = t(:please_sign_up)
      store_location
      redirect_to(:controller => 'users', :action => 'new')
    end
  end
  
  def remove_item
    OrderedItem.remove_from_user :user => current_user, :item_id => params[:id]
    @basket = current_user.basket
    @basket.save
    @basket.destroy if @basket.ordered_items.size == 0
    respond_to do |format|
      format.html do
        flash[:notice] = t(:item_removed_from_basket)
        redirect_to :back
      end
      format.js do

      end
    end
  end
  
  def delete_basket
    @basket = current_user.basket
    @basket.destroy if @basket
    redirect_to :action => :index
  end
  
  def change_deliver_on
    @basket = current_user.basket
    @days = Day.find :all
    @date = params[:id] ? Date.parse(params[:id]) : Date.parse(@basket.deliver_at.to_s)
    unless @basket
      render :action => "empty_basket"
    end
    
    respond_to do |format|
      format.html
      format.js {
        render :update do |page|
          page.replace_html "deliver_at", :partial => "change_deliver_at"
          page << "jQuery(function() {jQuery('#deliver_at input:first').datepicker({dateFormat: 'dd. mm. yy'});});"
        end
      }
    end
  end
  
  def set_deliver_on
    @basket = current_user.basket
    deliver_on = Date.parse(params[:deliver_on].sub(/(\d+)\.\ *(\d+)\.\ *(\d+)/,'\3-\2-\1'))
    if @basket
      disabled = @basket.disabled?
      #set date of delivery with leaving time untouched
      @basket.deliver_at = @basket.deliver_at.change :month => deliver_on.month, :year => deliver_on.year, :day => deliver_on.day
      
      if ((@stock = @basket.items_not_on_stock) != {})
        @basket.fix_amounts @stock
      end
      @basket.valid_without_callbacks?
      @basket.ordered_items.reload
      if @basket.ordered_items.size > 0
        respond_to do |format|
          format.js {
            render :update do |page|
              unless(disabled || @basket.disabled?)
                page.remove "notice"
                page.insert_html :top, "text", :partial => "shared/notice", :locals => {:message => t(:date_of_delivery_changed)}
                page.call "init_notice"
                page.replace_html "deliver_at", "#{format_date(@basket.deliver_at)} #{smart_link t(:change).mb_chars.capitalize, {:action => "change_deliver_on"}, :id => "deliver_at_link"}"
                page.visual_effect :highlight, "deliver_at", :duration => 0.5
                page.replace_html "order", :partial => "order"
                page.visual_effect :highlight, "order", :duration => 0.5
                page << "jQuery('input[name=update]').bind('click', update_basket);"
              else
                page << "window.location.reload();"
              end
            end
          }
          format.html {
            flash[:notice] = t(:date_of_delivery_changed)
            redirect_to :controller => :basket, :action => :index
          }
        end # end respond_to
      else
        @basket.destroy
        respond_to do |format|
          format.js {
            render :update do |page|
              page.replace_html "text", :partial => "empty_basket"
              page.remove "notice"
              page.insert_html :top, "text", :partial => "shared/notice", :locals => {:message => t(:item_cannot_be_added_to_basket)}
              page.call "init_notice"
            end
          }
          format.html {
            redirect_to :controller => :basket, :action => :index
          }
        end
      end
    else
      redirect_to :back
    end
    
  end
  protected
  def load_sidebar_content
    @polls ||= Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
    @news ||= News.valid_news :order => 'publish_at DESC, id DESC', :limit => 5
    @days ||= Day.find :all
    @date ||= params[:id] ? Date.parse(params[:id]) : Date.today
    
    @dialy_menu, @dialy_entries, @dialy_categories = load_dialy_menu
  end
end
