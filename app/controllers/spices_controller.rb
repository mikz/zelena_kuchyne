# -*- encoding : utf-8 -*-
class SpicesController < ApplicationController
  before_filter(:only => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins)}
  exposure
  
  def edit
    @suppliers = Supplier.find :all, :order => "name ASC"
    super
  end
  
  def new
    @suppliers = Supplier.find :all, :order => "name ASC"
    super
  end
end

