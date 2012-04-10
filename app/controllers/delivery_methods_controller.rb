# -*- encoding : utf-8 -*-
class DeliveryMethodsController < ApplicationController
    before_filter { |c| c.must_belong_to_one_of(:admins)}
    before_filter :load_zones, :only => [:create, :update, :edit, :new]
    exposure({
      :columns => [
        { :name => :basket_name , :proc => Proc.new {|i| i.name }},
        { :name => :price , :options => {:formatter => :currency}},
        { :name => :minimal_order_price , :options => {:formatter => :currency}},
        { :name => :zone, :proc => Proc.new {|z| z.name }}
      ],
      :form_fields => [
        { :name => :name, :type => :text_field},
        { :name => :basket_name, :type => :text_field},
        { :name => :price, :type => :text_field},
        { :name => :minimal_order_price, :type => :text_field},
        { :name => :zone_id, :type => :select, :data_proc => Proc.new {Zone.find(:all,:order => "name ASC", :conditions => "hidden = false").collect{|z| [ z.name, z.id ] } } }
       ],
    })
    
    
    private
    def load_zones
      @zones = Zone.find :all, :order => "name ASC" #, :conditions => "hidden = false",
    end
end

