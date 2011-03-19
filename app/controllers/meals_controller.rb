class MealsController < ApplicationController
  before_filter(:only => [:edit, :index]) { |c| c.must_belong_to_one_of(:admins, :warehousers, :operating_officers, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins)}
  
  exposure :columns => [:price, :cost, :updated_at]
  include_javascripts 'meals', 'flash_upload/jquery.flash', 'flash_upload/jquery.jqUploader', 'tooltip', 'fckeditor/fckeditor', 'fullscreen', 'jquery.autocomplete'
  include_stylesheets 'jquery.autocomplete'
  include FilterWidget
  
  def new
    @ingredients = Ingredient.find :all, :order => "name ASC", :conditions => "ingredients.supply_flag = false"
    @supplies = Ingredient.find :all, :order => "name ASC", :conditions => "ingredients.supply_flag = true"
    @categories = MealCategory.find :all, :order => "name ASC"
    @spices = Spice.find :all, :order => "name ASC"
    @meal_flags = MealFlag.find :all, :order => "name ASC"
    super
  end
  
  def edit
    @categories = MealCategory.find :all, :order => "name ASC"
    @ingredients = Ingredient.find :all, :order => "name ASC", :conditions => "ingredients.supply_flag = false"
    @supplies = Ingredient.find :all, :order => "name ASC", :conditions => "ingredients.supply_flag = true"
    @spices = Spice.find :all, :order => "name ASC"
    @meal_flags = MealFlag.find :all, :order => "name ASC"
    @record = Meal.find_by_id params[:id], :include => [:ingredients, :flagged_meals,:last_update_by]
    super
  end
  
  def index 
    conditions = []
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    @records = MealComputed.paginate(:all,:conditions => conditions.join(" AND "), :page => params[:page], :per_page => current_user.pagination_setting, :order => (params[:order] ? "meals_view."+params[:order] : 'meals_view.name') + ' ASC', :include => [:ingredients,:last_update_by])
    categories = MealCategory.find :all, :order => "name ASC"
    @categories = {}
    categories.each do |e|
      @categories[e.id] = e.name
    end
    respond_to do |format|
      format.js do 
        render :update do |page|
          page.replace 'records', :partial => 'index'
        end
      end
      format.json do
        render :text => Meal.find(:all, :conditions => conditions.join(" AND "), :order => "name ASC").to_json(
          :only => [:id, :item_id, :name]
        )
      end
      format.html do
        render
      end
    end 
  end
  
  def create
    meal_flags = MealFlag.find(params[:record].delete("meal_flag_ids")) unless params[:record]["meal_flag_ids"].blank?
    @record = Meal.new(params[:record])
    if(@record.save)
      @record.spice_ids = params['used_spice_ids']
      @record.meal_flags = meal_flags || []
      @record.save
      

      if(params['new_recipe'])
        params['new_recipe'].each do |ingredient_id, amount|
          Recipe.create(:ingredient_id => ingredient_id, :meal_id => @record.id, :amount => amount)
        end
      end  
    end
    
    super
    
    return unless @record.errors.empty?
    # save the picture with a thumbnail
    if(params['image_file'])
      @record.save_image params['image_file']
    end
  end
  
  def update
    @record = Meal.find_by_id params[:id], :include => :recipes
    params[:record]["meal_flag_ids"] ||= []
    if(@record.update_attributes(params['record']))
      @record.spice_ids = params['used_spice_ids']
        
      if(params['new_recipe'])
        params['new_recipe'].each do |ingredient_id, amount|
          Recipe.create(:ingredient_id => ingredient_id, :meal_id => @record.id, :amount => amount)
        end
      end
      
      if(params['recipe'])
        params['recipe'].each do |recipe_id, amount|
          
          if(amount.to_f == 0.0)
            Recipe.find(recipe_id).destroy
          else
            Recipe.update(recipe_id, {:amount => amount})
          end
        end
      end #if
    end
    
    super

    return unless @record.errors.empty?

    if(params['image_file'])
      @record.save_image params['image_file']
    end
    
    
  end #def
  
  def show
    @record = Meal.find params[:id]
    
    @scheduled = ScheduledItem.all :conditions => ["scheduled_for >= current_date AND item_id = ?", @record.item_id]
    super
  end
end