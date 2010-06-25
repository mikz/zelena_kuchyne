class LogbookCategoriesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins, :heads_of_car_pool)}
  exposure
end