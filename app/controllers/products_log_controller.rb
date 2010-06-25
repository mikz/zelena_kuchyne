class ProductsLogController < ApplicationController
  before_filter{ |c| c.must_belong_to_one_of(:admins, :warehousers)}
  exposure({
    :title => {:name => "day", :options => {:formatter => "date"}},
    :columns => [
      { :name => :product , :proc => Proc.new {|r| r.name }, :locale => "model_product", :order => "items.name"},
      { :name => :amount, :options => {:formatter => :amount} },
      { :name => :product_cost, :options => {:formatter => :currency}, :locale => "price"},
      { :name => :total_cost, :options => {:formatter => :currency}, :locale => "total_cost"}
    ],
    :form_fields => [
      { :name => :day, :type => :text_field, :options => {:class => "datepicker"} },
      { :name => :product, :type => :select, :locale => "model_product" },
      { :name => :amount, :type => :text_field , :note => :amount_unit},
      { :name => :note, :type => :text_field }
     ],
    :form => {:onload => %{$(".datepicker").datepicker();}},
    :calendar_widget => true,
    :dates_proc => Proc.new{ProductsLogEntry.days},
    :date_column => "day",
    :include => [:product, :last_update_by],
    :model => ProductsLogEntry
  })
  include_stylesheets 'jquery-ui'
  include FilterWidget
  
  
  def index
    conditions = []
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    dates = CalendarWidget.parse(params[:date]) if params[:date] 
    conditions.push "#{options[:date_column]||"date"} BETWEEN '#{dates[0]}' AND '#{dates[1]}'" if dates
    conditions = conditions.join(" AND ")
    
    @records = ProductsLogEntryView.paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting, :include => options[:include], :conditions => conditions, :order => (params[:order] || options[:title][:name]) + ' ASC')
    super
  end
  

  def balance
    @days = ProductsLog.all_days
    conditions = ["day <= ?", params[:date]] if params[:date]
    @records = ProductsLogBalanceView.paginate :all, :page => params[:page], :per_page => current_user.pagination_setting, :order => "products.name ASC", :conditions => conditions
    ProductsLogBalanceView.preload_products @records.collect{|r| r.product_id}
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace 'balance', :partial => "balance"
        end
      end
      format.xml do
        render :xml => @records
      end
    end
    ProductsLogBalanceView.erase_products
  end
  
  def warnings
    @days = ProductsLog.all_days
    conditions = []
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    dates = CalendarWidget.parse(params[:date]) if params[:date] 
    conditions.push "#{options[:date_column]||"date"} BETWEEN '#{dates[0]}' AND '#{dates[1]}'" if dates
    conditions = conditions.join(" AND ")
    @records = ProductsLogWarningView.paginate(:all, :include => {:ordered_item => :item}, :page => params[:page], :per_page => current_user.pagination_setting, :conditions => conditions, :order => (params[:order] || "id") + ' ASC')
     respond_to do |format|
        format.html
        format.js do
          render :update do |page|
            page.replace 'warnings', :partial => "warnings"
          end
        end
        format.xml do
          render :xml => @records
        end
      end
  end
  
  def destroy_warning
    ProductsLogWarning.find(params[:id]).destroy
    respond_to do |f|
      format f, :html do
        redirect_to :action => 'index'
      end
      format f, :xml do
        head :ok
      end
      format f, :js do
        render :action => "destroy"
      end
    end
  end
  
  def new
    @products = Product.find(:all,:order => "name ASC")
    super
  end
  
  def edit
    @products = Product.find(:all,:order => "name ASC")
    super
  end
  
  def create
    case params[:cost]["type"]
      when "auto"
      when "total"
        params[:record]["product_cost"] = params[:cost]["value"].to_f / params[:record]["amount"].to_f
      when "unit"
        params[:record]["product_cost"] = params[:cost]["value"]
    end if params[:cost]
    update_product = !params[:update_product_cost].nil?
    super
    if update_product
      @record.product.cost = @record.product_cost
      @record.product.save
    end
  end
  
  def update
    case params[:cost]["type"]
      when "auto"
      when "total"
        params[:record]["product_cost"] = params[:cost]["value"].to_f / params[:record]["amount"].to_f
      when "unit"
        params[:record]["product_cost"] = params[:cost]["value"]
    end if params[:cost]
    update_product = !params[:update_product_cost].nil?

    super
    if update_product
      @record.product.cost = @record.product_cost
      @record.product.save
    end
  end
  
end