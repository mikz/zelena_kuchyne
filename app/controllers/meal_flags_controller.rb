class MealFlagsController < ApplicationController
  before_filter(:only => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins, :chefs)}
  before_filter(:except => [:edit, :index, :show]) { |c| c.must_belong_to_one_of(:admins)}
  exposure :columns => [:description, :icon_path, :in_dialy_menu]
  
  include_javascripts 'flash_upload/jquery.flash', 'flash_upload/jquery.jqUploader'
  
  def create
    super
    if(params['image_file'])
      @record.save_image params['image_file']
    end
  end
  
  def update
    super
    if(params['image_file'])
      @record.save_image params['image_file']
    end
  end
end
