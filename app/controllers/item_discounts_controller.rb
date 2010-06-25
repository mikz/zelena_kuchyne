class ItemDiscountsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure :columns => [:amount,:start_at,:expire_at,:note]
  
  include_javascripts  'discounts'
  include_stylesheets 'jquery-ui'
  
  def new
    @meals = Meal.find :all, :order => "name ASC"
    @menus = Menu.find :all, :order => "name ASC"
    @bundles = Bundle.find :all, :order => "name ASC"
    @products = Product.find :all, :order => "name ASC"
    super
  end

  def edit
    @meals = Meal.find :all, :order => "name ASC"
    @menus = Menu.find :all, :order => "name ASC"
    @bundles = Bundle.find :all, :order => "name ASC"
    @products = Product.find :all, :order => "name ASC"
    super
  end
end