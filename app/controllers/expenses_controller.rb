class ExpensesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :operating_officers, :warehousers)}
  include_javascripts "jquery.autocomplete", 'calendar_widget', "fullscreen"
  include_stylesheets "jquery.autocomplete", "jquery-ui"
  include FilterWidget
  
  
  exposure({
    :title => "name",
    :columns => [
      {:name => :price, :options => { :formatter => :currency } },
      {:name => :bought_at, :options => {:formatter => :date} },
      {:name => :expense_owner, :proc => Proc.new{|e|I18n.t("expense_owner_#{e}")}},
      {:name => :expense_category, :proc => Proc.new{|c| c.name }, :order => "expense_categories.name", :locale => "attr_category"},
      :user_login
    ],
    :form_fields => [
      { :name => :name,         :type => :text_field, :options => {:class => "autocomplete name"}},
      { :name => :price,        :type => :text_field, :options => {:onkeyup => "decimal_dot_conversion(this)"} },
      { :name => :bought_at,    :type => :text_field, :options => {:class => "datepicker"} },
      { :name => :user_login,   :type => :text_field, :options => {:class => "autocomplete users"} },
      { :name => :expense_category_id, :type => :select, :data_proc => Proc.new{ExpenseCategory.find(:all).collect{|c| [c.name, c.id]}}, :options => {:include_blank => true}, :locale => "attr_category", :selected => Proc.new {|e| e.expense_category_id}},
      { :name => :expense_owner, :type => :select, :data_proc => Proc.new{Expense.expense_owners}},
      { :name => :premise_id,   :type => :select, :data_proc => Proc.new{Premise.find(:all).collect{|p| [p.name, p.id]}}, :options => {:include_blank => true}},
      { :name => :note,         :type => :text_field, :options => {:class => "autocomplete note"} }
    ],
    :form => {:onload => %{$('.datepicker').datepicker(); $('.autocomplete.users').autocomplete('/users/find/'); $('.autocomplete.name').autocomplete('/expenses/autocomplete/?type=name', expenses); $('.autocomplete.note').autocomplete('/expenses/autocomplete/?type=note', expenses);}},
    :calendar_widget => true,
    :dates_proc => Proc.new{Expense.days.collect{|day| Date.parse(day) } }
  })
  
  def index
    conditions = []
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    
    @categories = {}
    ExpenseCategory.find(:all, :order => "name ASC").each do |e|
      @categories[e.id] = e.name
    end
    @premises = {}
    Premise.find(:all).each { |p|
      @premises[p.id] = p.name
    }
    @owners = {}
    Expense.expense_owners.each { |o|
      @owners[o.last] = o.first
    }
    dates = CalendarWidget.parse params[:date]
    @records = Expense.paginate(:all, :conditions => ["#{conditions.join(" AND ") + ' AND ' unless conditions.empty?}bought_at::date BETWEEN ? AND ?", dates[0], dates[1]],:page => params[:page], :include => [:expense_category])
    super
  end
  
  def autocomplete
    @values = Expense.find_values params[:type], params[:q], params[:limit], true
    respond_to do |format|
      format.js do 
        render :json => @values.to_json
      end
    end
  end
end