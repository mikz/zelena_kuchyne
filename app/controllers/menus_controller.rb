class MenusController < ApplicationController
  before_filter(:only => [:index, :show, :edit]) { |c| c.must_belong_to_one_of(:admins, :operating_officers, :chefs)}
  before_filter(:except => [:index, :show, :edit]) { |c| c.must_belong_to_one_of(:admins, :operating_officers)}
  include_javascripts 'tooltip', 'fckeditor/fckeditor', 'fullscreen'
  exposure :columns => [:price,:cost,:updated_at]
  
  def index
    @records = MenuComputed.paginate(:all, :page => params[:page], :per_page => current_user.pagination_setting, :order => (params[:order] ? "menus_view."+params[:order] : 'menus_view.name') + ' ASC', :include => [:meals,:last_update_by])
    super
  end  
  
  def new
    @categories = MealCategory.find(:all, :order => "name ASC")
    @meals = {}
    @courses = {}
    @categories.each do |category|
      @meals[category.id] = Meal.find(:all, :conditions => "meal_category_id = #{category.id}")
    end
    super
  end
  
  def edit
    @record = Menu.find params[:id], :include => [:meals], :order => "name ASC"
    @categories = MealCategory.find(:all)
    @meals = {}
    @categories.each do |category|
      @meals[category.id] = Meal.find(:all, :conditions => "meal_category_id = #{category.id}", :order => "name ASC")
    end
    @courses = {}
    @record.meals.each do |meal|
      @courses[meal.meal_category_id] = meal.id
    end
    super
  end
  
  def create
    meal_ids = params[:record].delete("meal_ids")
    @record = Menu.new(params[:record])
    @record.save
    @record.meal_ids = meal_ids
    super
  end
  
  def update
    @record = MenuComputed.find_by_id params[:id]
    super
  end
end
