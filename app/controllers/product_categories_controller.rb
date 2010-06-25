class ProductCategoriesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts 'fckeditor/fckeditor'
  exposure
  
  
  include_javascripts 'product_categories'
  
  def new
    @product_categories = ProductCategory.find :all, :order => "lft ASC"
    super
  end
  
  def edit
    @product_categories = ProductCategory.find :all, :order => "lft ASC"
    super
  end
  
  def create
    @record = ProductCategory.create(params[:record])
    @record.move_to_child_of(params[:record]['parent_id']) unless params[:record]['parent_id'].empty?
    expire_fragment(%r{category_(tree|sub)_\d*})
    super
  end
  
  def update
    @record = ProductCategory.find_by_id params[:record]['id']
    @record.move_to_child_of params[:record]['parent_id']
    expire_fragment(%r{category_(tree|sub)_\d*})
    super
  end
end
