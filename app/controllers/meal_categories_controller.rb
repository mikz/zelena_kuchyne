# -*- encoding : utf-8 -*-
class MealCategoriesController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  exposure
end
