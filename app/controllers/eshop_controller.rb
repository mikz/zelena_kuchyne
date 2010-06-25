class EshopController < ApplicationController
  active_section "eshop"
  include_stylesheets 'eshop'
  
  def index
    fragment_category = fragment_exist?("category_tree_#{params[:category] || 0}") && fragment_exist?("category_sub_#{params[:category] || 0}")
    if(params[:category] &&  (@category = ProductCategory.find_by_id params[:category]))
      @descendants_ids = @category.self_and_descendants.map! do |c|
        c.id
      end
      unless fragment_category
        @ancestors = @category.self_and_ancestors
        @ancestors_ids = @ancestors.map do |a|
          a.id
        end
      end
      @products = ProductWithStock.paginate :all, :include => [:categorized_products], :conditions => "categorized_products.product_category_id in (#{@descendants_ids.join(",")}) AND disabled IS NOT TRUE", :order => "name", :page => params[:page]
    else
      @product_categories = ProductCategory.find :all, :order => "lft ASC", :conditions => "parent_id IS NULL" unless fragment_category
      @products = ProductWithStock.paginate :all, :include => [:categorized_products], :page => params[:page], :order => "name", :conditions => ["disabled IS NOT TRUE "]
    end
  end
  
  def product
    params[:id] = params[:id].split("-").first.to_i
    @product = ProductWithStock.find params[:id], :include => [:categorized_products]
  end
  
  def zbozi
    @products = ProductWithStock.find :all, :order => "name", :conditions => "disabled IS NOT TRUE"
    respond_to do |format|
      format.xml
    end
  end
  
  protected
  def load_polls
    @polls = Poll.find_all_by_active true, :include => [:poll_votes, :poll_answers_results], :order => "created_at DESC"
  end
end