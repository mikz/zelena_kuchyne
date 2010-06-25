class CarsLogbooksController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :deliverymen, :heads_of_car_pool)}
  
  include_javascripts "jquery.autocomplete", 'calendar_widget', 'fullscreen'
  include_stylesheets "jquery.autocomplete", "jquery-ui"
  include FilterWidget
  
  exposure({
    :title => {:name => "registration_no", :order => "cars.registration_no", :proc => Proc.new {|l| "#{l.car.registration_no} #{l.car.note}"} },
    :columns => [
      { :name => :user_login, :locale => "driver"},
      { :name => :date },
      { :name => :beginning_in_kilometers, :locale => "attr_beginning", :order => "beginning", :options => {:formatter => "distance"} },
      { :name => :ending_in_kilometers, :locale => "attr_ending", :order => "ending", :options => {:formatter => "distance"} },
      { :name => :private_distance_in_kilometers, :locale => "attr_private_distance", :order => "private_distance", :options => {:formatter => "distance"} },
      { :name => :business_distance_in_kilometers, :locale => "attr_business_distance", :order => "business_distance", :options => {:formatter => "distance"}}
    ],
  :form_fields => [
       { :name => :car_id, :type => :select, :data_proc =>  Proc.new {Car.find(:all,:order => "registration_no ASC").collect{|p| [ "#{p.registration_no} #{p.note}", p.id ] } }, :locale => "attr_car", :selected => Proc.new {|l| l.car_id} },
       { :name => :user_login,   :type => :text_field, :options => {:class => "autocomplete" }, :locale => "driver" },
       { :name => :date, :type => :text_field, :options => {:class => "datepicker"}},
       { :name => :beginning_in_kilometers, :locale => "attr_beginning", :type => :text_field, :note => "distance_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"}},
       { :name => :ending_in_kilometers, :locale => "attr_ending", :type => :text_field, :note => "distance_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"}},
       { :name => :private_distance_in_kilometers, :locale => "attr_private_distance", :type => :text_field, :note => "distance_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"}},
       { :name => :business_distance_in_kilometers, :locale => "attr_business_distance", :type => :text_field, :note => "distance_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"}},
       { :name => :logbook_category_id, :type => :select, :data_proc =>  Proc.new {LogbookCategory.find(:all,:order => "name ASC").collect{|c| [c.name, c.id]} }, :locale => "attr_category", :options => {:include_blank => true}, :selected => Proc.new {|l| l.logbook_category_id} }
     ],
   :form => {:onload => "$('.datepicker').datepicker();$('.autocomplete').autocomplete('/users/find/');"},
   :calendar_widget => true,
   :dates_proc => Proc.new{CarsLogbook.days.collect{|day| Date.parse(day) } },
   :include => [:car, :user]
  })
  
  def index
    @cars = {}
    Car.find(:all, :order => "registration_no ASC").each do |e|
      @cars[e.id] = "#{e.registration_no} #{e.note}"
    end
    conditions = []
    params[:filter].each { |f|
      f[:value] = f[:value].to_f * 1000 if ["private_distance","business_distance", "beginning","ending"].include?(f[:attr])
    } if params[:filter]
    conditions.push "#{filter_widget_conditions(params[:filter])}" if params[:filter].is_a?(Array)
    dates = CalendarWidget.parse(params[:date]) if params[:date] 
    conditions.push "#{options[:date_column]||"date"} BETWEEN '#{dates[0]}' AND '#{dates[1]}'" if dates
    conditions = conditions.join(" AND ")
    @sums = CarsLogbook.find(:all, :select => "car_id, user_id, MIN(date) AS from, MAX(date) AS to, MIN(beginning) AS beginning, MAX(ending) AS ending, SUM(business_distance) AS business_distance, SUM(private_distance) AS private_distance", :group => "car_id, user_id", :conditions => conditions)
    super
  end
end