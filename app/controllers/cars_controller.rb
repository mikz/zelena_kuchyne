class CarsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :deliverymen, :heads_of_car_pool)}
  
  exposure({
    :title => "registration_no",
    :columns => [
      { :name => :note},
      { :name => :fuel_consumption, :options => {:formatter => "amount", :unit => "fuel_consumption_unit"} }
    ],
  :form_fields => [
       { :name => :registration_no,   :type => :text_field },
       { :name => :note,              :type => :text_field },
       { :name => :fuel_consumption,  :type => :text_field, :note => "fuel_consumption_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"} }
     ]
  })
  
end