class NewsController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure :title => 'title'
  include_javascripts 'schedule', 'fckeditor/fckeditor', 'calendar_widget'
  include_stylesheets 'jquery-ui'
end
