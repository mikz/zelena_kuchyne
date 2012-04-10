# -*- encoding : utf-8 -*-
class Recipe < ActiveRecord::Base
  belongs_to :meal
  belongs_to :ingredient
end

