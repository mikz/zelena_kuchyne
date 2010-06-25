class FuelController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :deliverymen, :heads_of_car_pool)}
  include_javascripts "jquery.autocomplete", 'fullscreen'
  include_stylesheets "jquery.autocomplete", 'jquery-ui'
  include FilterWidget
  exposure({
    :title => "date",
    :columns => [
      {:name => "registration_no", :order => "cars.registration_no"},
      { :name => :user_login, :locale => "driver", :order => "users.login"},
      {:name => :cost, :options => {:formatter => "currency"}},
      {:name => :amount }
    ],
    :form_fields => [
      { :name => :car_id, :type => :select, :data_proc =>  Proc.new {Car.find(:all,:order => "registration_no ASC").collect{|p| [ "#{p.registration_no} #{p.note}", p.id ] } }, :locale => "attr_car", :selected => Proc.new{|f| f.car_id } },
      { :name => :user_login, :type => :text_field, :options => {:class => "autocomplete"}, :locale => "driver" },
      { :name => :date,       :type => :text_field, :options => {:class => "datepicker"} },
      { :name => :amount,     :type => :text_field, :note => :fuel_unit, :options => {:onkeyup => "decimal_dot_conversion(this)"}  },
      { :name => :cost,       :type => :text_field, :note => :currency_unit, :options => {:onkeyup => "decimal_dot_conversion(this)"} },
      { :name => :note,       :type => :text_field }
    ],
    :form => {:onload => %{$(".autocomplete").autocomplete('/users/find/');$(".datepicker").datepicker();}},
    :include => [:car,:user],
    :calendar_widget => true,
    :dates_proc => Proc.new{Fuel.days.collect{|day| Date.parse(day) } }
  })
  
  def index
    @cars = {}
    Car.find(:all, :order => "registration_no ASC").each do |e|
      @cars[e.id] = "#{e.registration_no} #{e.note}"
    end
    conditions = []
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    dates = CalendarWidget.parse(params[:date]) if params[:date] 
    conditions.push "#{options[:date_column]||"date"} BETWEEN '#{dates[0]}' AND '#{dates[1]}'" if dates
    conditions = conditions.join(" AND ")
    @sums = Fuel.find(:all, :select => "car_id, user_id, MIN(date) AS from, MAX(date) AS to, SUM(cost) AS cost, SUM(amount) AS amount", :group => "fuel.car_id, 
fuel.user_id", :conditions => conditions)
    super
  end
end
