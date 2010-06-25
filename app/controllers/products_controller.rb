class ProductsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure(:columns => [
    { :name => :price, :options => {:formatter => :currency} },
    { :name => :cost, :options => {:formatter => :currency}, :locale => :cost }
  ])
  include FilterWidget
  include_javascripts 'product_categories', 'flash_upload/jquery.flash', 'flash_upload/jquery.jqUploader', 'fckeditor/fckeditor'
  include_stylesheets 'ui.slider'

  def index
    @categories = ProductCategory.find :all, :order => "lft ASC"
    conditions = filter_widget_conditions(params[:filter]) if params[:filter].is_a? Array
    if conditions
      @records = Product.find :all, :conditions => conditions, :include => :product_categories, :order => "products.#{params[:order]||"name"}"
    else
      @records = Product.paginate :include => :product_categories, :order => "products.#{params[:order]||"name"}", :page => params[:page]
    end
    respond_to do |format|
      format.html
      format.js do 
        render :update do |page|
          page.replace "records", :partial => "index"
          page << "filterWidget('records-rules').updateOptions({url: #{url_for(params.delete_if {|key,val| key == 'filter'}).gsub('&amp;', '&').inspect}});" if @options[:filter_widget]
        end
      end 
      format.xml do
        render :xml => @records
      end
      format.json {
        render :json => ProductWithStock.find(:all, :conditions => conditions, :include => :product_categories, :order => "products_with_stock_view.#{params[:order]||"name"}").to_json(:only => [:id, :item_id, :name, :amount])
      }
    end
  end

  def new 
    @product_categories = ProductCategory.find :all, :order => "lft ASC"

    super
  end
  
  def create
    product_category_ids = params[:record].delete("product_category_ids")
    @record = Product.new(params[:record])
    @record.save
    @record.product_category_ids = product_category_ids
    if(params['image_file'])
      @record.save_image params['image_file']
    end
    super
  end
  
  def edit 
    @product_categories = ProductCategory.find :all, :order => "lft ASC"
    @record = Product.find_by_id params[:id], :include => :categorized_products
    super
  end
  
  def update
    super
    
    if(params['image_file'])
      @record.save_image params['image_file']
    end
  end
end
