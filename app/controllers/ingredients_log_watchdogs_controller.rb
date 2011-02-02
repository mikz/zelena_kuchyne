class IngredientsLogWatchdogsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :operating_officers)}
  
  exposure(
    :title => {:proc => Proc.new{|w| w.ingredient.name }, :name => "ingredient", :order => "ingredients.name"},
    :columns => [
      {:name => :operator},
      {:name => :value }
    ],
    :form_fields => [
      { :name => :ingredient, :type => :select, :data_proc => Proc.new {Ingredient.find(:all,:order => "name ASC").collect{|i| [ i.name, i.id ] } } },
      { :name => :operator, :type => :select, :data_proc => Proc.new{[['e','='],['lt','<'],['gt','>'],['ltoe','<='],['gtoe','>='],['ne','!=']].collect{|o| [I18n.t("operator_#{o.first}"),o.last] }} },
      { :name => :value, :type => :text_field}
    ]
  )
  
  def new
    @options[:form_fields].each {|field|
      field[:data] = field[:data_proc].call if field[:data_proc].is_a?(Proc)
    }
    super
  end
  
  def edit
    @record =  IngredientsLogWatchdog.find_by_id params[:id]
    @options[:form_fields].each {|field|
      if field[:type] == :select
        field[:data] = field[:data_proc].call if field[:data_proc].is_a?(Proc)
        field[:selected] = @record.send(field[:name]).id
      end
    }
    super
  end
  
  def index
    @records = IngredientsLogWatchdog.find :all, :include => :ingredient, :order => params[:order] || @options[:title][:order]
    super
  end
  
  def create
    params[:record]["ingredient"] = Ingredient.find_by_id(params[:record]["ingredient"])
    super
  end
  
  def create
    params[:record]["ingredient"] = Ingredient.find_by_id(params[:record]["ingredient"])
    super
  end
end