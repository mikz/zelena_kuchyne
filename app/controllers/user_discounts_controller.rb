class UserDiscountsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure :title => "user" ,:columns => [:name,:note,:amount,:start_at,:expire_at,:cancelled_at,:discount_class]
  
  include_javascripts 'discounts', 'jquery.autocomplete', 'fullscreen'
  include_stylesheets 'jquery-ui', 'jquery.autocomplete'
  
  def index
    @records = UserDiscount.paginate(:all, :include => [{:user => :user_profiles}], :page => params[:page], :per_page => current_user.pagination_setting, :order => (params[:order] ? params[:order] : "user") + ' ASC')
    super
  end
  
  def create
    params[:record]['user'] = User.find_by_login params[:record]['user']
    super
  end
  
  def update
    params[:record]['user'] = User.find_by_login params[:record]['user']
    super
  end
  
  def destroy
    @record = UserDiscount.find_by_id(params[:id])
    if (@record.destroy > 0)
      respond_to do |f|
        format f, :html do
          redirect_to :action => 'index'
        end
        format f, :xml do
          head :ok
        end
        format f, :js do
          render
        end
      end
    else
      @record.reload
      respond_to do |f|
        format f, :html do
          flash[:notice] = locales[:user_discount_cancelled]
          redirect_to :action => 'index'
        end
        format f, :js do
          flash[:notice] = locales[:user_discount_cancelled]
          render :action => "show"
        end
      end
    end
  end
end
