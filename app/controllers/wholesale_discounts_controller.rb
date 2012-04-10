# -*- encoding : utf-8 -*-
class WholesaleDiscountsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  include_javascripts "jquery.autocomplete"
  include_stylesheets "jquery.autocomplete", 'jquery-ui'

  exposure({
    :title => {:name => "user", :proc => Proc.new {|u| u.user.login }, :order => "users.login" },
    :columns => [
      {:name => "discount_price", :locale => "attr_order_price", :options => {:formatter => "currency"} },
      {:name => :start_at, :options => {:formatter => "date"} },
      {:name => :note }
    ],
    :form_fields => [
      { :name => :user_login,     :type => :text_field, :options => {:class => "autocomplete"} },
      { :name => :discount_price, :type => :text_field, :locale => "attr_order_price", :note => "currency_unit", :options => {:onkeyup => "decimal_dot_conversion(this)"} },
      { :name => :start_at,       :type => :text_field, :options => {:class => "datepicker"} },
      { :name => :expire_at,      :type => :text_field },
      { :name => :note,           :type => :text_field }
    ],
    :form => {:onload => %{$(".autocomplete").autocomplete('/users/find/');$(".datepicker").datepicker();}},
    :include => [:user]
  })
  
end

