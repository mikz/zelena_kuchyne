class SuppliersController < ApplicationController
  before_filter(:only => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :warehousers, :operating_officers, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins)}
  exposure :columns => [:name, :name_abbr], :form_fields => {:name => :text_field, :name_abbr => :text_field, :address => :text_area}
  include_javascripts 'fckeditor/fckeditor', 'tooltip'
end
