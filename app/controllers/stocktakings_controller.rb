class StocktakingsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure({
    :title => {:name => "date",:options => {:formatter => "date"} },
    :form => {:onload => %{$(".datepicker").datepicker();}}
  })
  include_javascripts 'stocktakings', 'fullscreen'
  include_stylesheets 'jquery-ui'
  
  def edit
    @record = Stocktaking.find_by_id params[:id], :include => :ingredient_consumptions
    @consumptions = {}
    @record.ingredient_consumptions.each do |o|
      @consumptions[o.ingredient_id] = o
    end
    super
  end
  
  def balance
    @balance = IngredientsLogEntry.balance :day => params[:date] || Date.today , :order => "ingredient_name ASC", :paginate => false
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html params[:row_id]+"_ingredients", :partial => "ingredients", :locals => {:row_id => params[:row_id]}
        end
      }
    end
  end
  
  def delete_consumption
    @record = IngredientConsumption.find :first, :conditions => ["ingredient_id = ? AND stocktaking_id = ?", params[:ingredient_id].to_i, params[:stocktaking_id].to_i]
    @record.destroy
    respond_to do |format|
      format.js {
        render :update do |page|
          page << "jQuery('#ingredient_#{@record.ingredient_id} td.consumption').html('');"
        end
      }
    end
  end
end
