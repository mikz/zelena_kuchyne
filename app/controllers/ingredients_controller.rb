class IngredientsController < ApplicationController
  before_filter(:only => [:index, :search, :edit, :show]) { |c| c.must_belong_to_one_of(:admins, :warehousers, :operating_officers, :chefs)}
  before_filter(:except => [:index, :edit, :show]) { |c| c.must_belong_to_one_of(:admins, :warehousers)}
  exposure :columns => [:cost, :unit, :code, :supply_flag]
  
  def edit
    @suppliers = Supplier.find :all
    super
  end

  def search
    like = "%#{params[:q]}%"
    if params[:filter]
     conditions = " AND #{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    end
    @record = Ingredient.find :all, :conditions => ["name ILIKE ? #{conditions if conditions}", like], :limit => params[:limit] || 10
     respond_to do |format|
      format.js do
        render :json => @record.to_json
      end
    end
  end

  def new
    @suppliers = Supplier.find :all
    super
  end
end
