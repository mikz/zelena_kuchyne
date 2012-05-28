# -*- encoding : utf-8 -*-

class UsersController < ApplicationController
  before_filter(:except => [:signin, :signup, :signout, :new, :create, :edit, :find, :update, :set_interface_language, :show, :validate_user, :forgotten_password, :new_password, :generate_password]) {|c| c.must_belong_to_one_of([:admins])}
  before_filter(:only => :find) {|c| c.must_belong_to_one_of(:admins, :deliverymen, :heads_of_car_pool, :warehousers)}
  before_filter(:only => :set_zone) {|c| c.must_belong_to_one_of(:admins, :deliverymen)}
  
  before_filter :load_zones, :only => [:new, :create, :edit, :update, :index]
  include_javascripts 'user_form', 'jquery.colorpicker'
  include_javascripts 'fullscreen', :only => [:index]
  include_stylesheets 'jquery.colorpicker'
  include FilterWidget

  def signin
    basket = current_user.basket
    return head(:bad_request) unless params.has_key(:user)

    if(self.current_user = User.authenticate(params['user']['login'], params['user']['password']))
      if basket
        current_user.basket.destroy if current_user.basket
        basket.user_id = current_user.id
        basket.save
      end
      respond_to do |format|
        format.html do
          flash[:notice] = t(:signed_in)
          redirect_to :back
        end
        format.js do
          render :update do |page|
            page << 'window.location.reload();'
          end
        end
        format.xml do
          head :ok
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:notice] = t(:bad_login)
          redirect_to :back
        end
        format.js do
          render :update do |page|
            page.visual_effect :shake, 'user_form'
          end
        end
        format.xml do
          head :unauthorized
        end
      end
    end
  end
  
  def signout
    reset_session
    respond_to do |format|
      format.html do
        flash[:notice] = t(:signed_out)
        redirect_to :back
      end
      format.js do
        render :update do |page|
          page << 'window.location.reload();'
        end
      end
      format.xml do
        head :ok
      end
    end
  end
  
  def validate_user
    respond_to do |format|
      format.js do
        render :text => User.find(:first, :conditions => ["login = ?", params[:user]['login']]).blank?.inspect
      end
    end
  end
  
  def set_zone
    @user = User.find params[:id]
    @address = @user.delivery_address
    @address.dont_validate = true
    @address.update_attributes(params[:zone])
    respond_to do |format|
      format.js {
        render :update do |page|
          case params[:from]
          when "orders"
            @order = OrderView.find params[:order_id]
            @delivery_men = DeliveryMan.find :all
            id = "order_#{@order.id}}"
            partial = 'orders/order'
            locals = {:order => @order, :delivery_men => @delivery_men}
          when "users"
            id = "user_#{@user.id}"
            partial = 'users/show'
            locals = {:user => @user.user_view}
          end
          page.replace id, :partial => partial, :locals => locals
          page.visual_effect :highlight, id
        end
      }
    end
  end
  
  
  def index
    condition = "(#{params[:q].blank?} OR (login ILIKE ? OR users_view.first_name ILIKE ? OR users_view.family_name ILIKE ? OR users_view.company_name ILIKE ?))"
    query = "%#{params[:q]}%" if params[:q]
    order = nil
    case params[:order]
      when "user_discount"
        order = "COALESCE(user_discount,0) DESC"
      when "spent_money"
        order = "spent_money DESC"
      else
        order = (params[:order].blank?)? "login" : params[:order]
    end
    
    @users = UsersView.scoped(:order => order, :include => {:addresses => :zone})
    if params[:id] and params[:id].length > 0
      @selected = ''
      @users = @users.scoped(:include => {:groups => :memberships}, :conditions => ["groups.system_name = ? AND #{condition}", params[:id], query, query, query, query])
    else
      @users = @users.scoped(:order => order, :conditions => ["guest = false AND #{condition}", query, query, query, query])
      @selected = 'selected="selected"'
    end
    @groups = Group.find :all
    
    
    respond_to do |format|
      format.html do
        @users = @users.paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting)
      end
      format.xls do
        send_data(@users.scoped(:include => {:addresses => :zone}).to_xls(
                          :only => [:login, :name, :email, :spent_money, :user_discount],
                          :methods => [:zone_name, {
                            :address => [:street, :house_no, :city, :district, :zip, :note]
                          }]), :filename => 'users.xls')
      end
    end
  end
  
  def new
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    
    respond_to do |format|
      format.html do
        @profile_types = UserProfileType.find(:all, :conditions => 'editable = true')
        @user = User.new
        session[:return_to] ||= request.referer
        render :action => 'new'
      end
    end
  end
  
  def create
    @user = User.new params[:user]
    
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    @user.user_agreement =  (params[:user].delete("user_agreement") == "on")
    if(@user.save)
      basket = current_user.basket
      self.current_user = User.authenticate(params[:user]['login'], params[:user]['password'])
      if basket
        basket.user_id = current_user.id
        basket.save
      end
      respond_to do |format|
        format.html do
          flash[:notice] = t(:signup_completed)
          redirect_back_or_default '/'
        end
        format.xml do
          render :xml => @user, :status => :created, :location => @user
        end
        format.js do
          render :update do |page|
            url = session[:return_to] ? session[:return_to] : url_for(:controller => 'welcome', :action => 'index')
            page << %{window.location = "#{url}";}
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          @profile_types = UserProfileType.find(:all)
          render :action => 'new'
        end
        format.xml do
          render :xml => @user.errors, :status => 422
        end
        format.js do
          #update_notice @user.errors #TODO: update_notice is non-existent
          render :update do |page|
#            page.replace_html "validation_error",  
            page << %{$("#validation_error").formatError(#{@user.errors.to_json});}
            page << %{$("#home_address_dont_validate").parent().show();}
            page << %{$("#delivery_address_dont_validate").parent().show();}
            page.visual_effect :appear, "validation_error"
          end
        end
      end
    end
  end
  
  def show
    @user = User.find params[:id], :include => [:user_discounts, :active_user_discount]
    unless @user.id == current_user.id
      must_belong_to_one_of :admins
    end
    respond_to do |format|
      format.html do
        render
      end
      format.xml do
        render :xml => @user
      end
    end
  end
  
  def edit
    @user = User.find(params[:id], :include => [:user_profiles, :user_discounts, :active_user_discount])
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    
    unless @user.id == current_user.id
      must_belong_to_one_of :admins
    end
    respond_to do |format|
      format.html do
        session[:return_to] ||= request.referer
        @profile_types = UserProfileType.find(:all, :conditions => 'editable = true')
        render
      end
    end
  end
  
  def update
    @user = User.find(params[:id], :include => [:user_profiles, :addresses])
    @groups = Group.find :all
    @country_codes = CountryCode.find :all, :select => "code", :group => "code", :order => "code"
    unless @user.id == current_user.id
      must_belong_to_one_of :admins
    end
    if current_user.belongs_to?(:admins)
      @user.imported_orders_price = params[:user]["imported_orders_price"]
      @user.admin_note = params[:user]["admin_note"]
    end
    
    if(@user.update_attributes(params[:user]) && @user.errors.empty?)
      respond_to do |format|
        format.html do
          redirect_to :action => 'show', :id => @user
        end
        format.xml do
          head :ok
        end
        format.js do
          render :update do |page|
            if session[:return_to]
              page << "window.location = '#{session[:return_to]}'"
              session[:return_to] = nil
            else
              page << 'window.location = \'/\''
            end
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          render :action => 'edit'
        end
        format.xml do
          render :xml => @user.errors, :status => 422
        end
        format.js do
          #update_notice @user.errors #TODO: update_notice is non-existent
          render :update do |page|
#            page.replace_html "validation_error",  
            page << %{$("#validation_error").formatError(#{@user.errors.to_json});}
            page << %{$("#home_address_dont_validate").parent().show();}
            page << %{$("#delivery_address_dont_validate").parent().show();}
            page.visual_effect :appear, "validation_error"
          end
        end
      end
    end
  end

  def test_form
    respond_to do |format|
      format.html do
        @profile_types = UserProfileType.find(:all, :conditions => 'editable = true')
        @user = User.new
        render
      end
    end
  end
  
  def test
    @user = User.new(params[:user])
    flash[:notice] = "V pořádku" if @user.valid?
    respond_to do |format|
      format.html do
        render :action => 'test_form'
      end
      format.js do
        #update_notice @user.errors #TODO: update_notice is non-existent
        render :update do |page|
#          page.replace_html "validation_error",  
          page << %{$("#validation_error").formatError(#{@user.errors.to_json});}
          page.visual_effect :appear, "validation_error"
        end
      end
    end
  end

  def destroy
    User.find(params[:id]).destroy
    respond_to do |format|
      format.html do
        redirect_to :action => 'index'
      end
      format.xml do
        head :ok
      end
    end
  end
  
  def create_order
    user = User.find(params[:id])
    order = user.orders.build({:deliver_at => Time.now, :state => 'order'})
    order.save_without_validation!
    
    redirect_to :controller => 'orders', :action => 'edit', :id => order.id
  end
  
  def set_interface_language
    if language_exists? params[:language]
      current_user.interface_language = params[:language]
      current_user.save
    else
      flash[:notice] = "Language '#{params[:language]}' does not exists."
    end
    redirect_to :back
  end
  
  def find
    like = "%#{params[:q]}%"
    if params[:filter]
     conditions = " AND #{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    end

    @users = UsersView.find :all, :limit => params[:limit], :include => {:groups => :memberships}, :conditions => ["guest = ? AND (login ILIKE ? OR first_name ILIKE ? OR family_name ILIKE ? OR company_name ILIKE ?)#{conditions if conditions}", false, like, like, like, like]

    respond_to do |format|
      format.js do 
        render :json => @users.to_json, :only => [:login, :first_name, :family_name]
      end
    end
  end
  
  def new_password
    @user = User.find_by_id params[:id]
    @token = params[:auth]
    user_token = @user.user_token

    if user_token && user_token.token == @token && @token.length == 32
      render
    else
      render :action => "token_dont_match"
    end
  end
  
  def generate_password
    @user = User.find_by_id params[:id]
    @token = params[:auth]
    if @user.user_token.nil?
      redirect_to "/"
      return
    end
    if @user.user_token.token == @token and @token.length == 32 and ((Time.now-@user.user_token.created_at) - 1.day < 0)
      @password = @user.password = User.random_password
      if(@user.save_without_validation)
        UserToken.delete_all ["user_id = ?", @user.id]
        respond_to do |format|
          format.html do 
            render
          end
        end
      else
        respond_to do |format|
          format.html do
            flash[:notice] = t(:problem_when_generating_password)
            redirect_to :back
          end
        end
      end
    else
      render :action => "token_dont_match"
    end
  end
  
  private
  def load_zones
    @zones = Zone.all :conditions => ["hidden = ?", false], :order => "name ASC"
  end
end

