# -*- encoding : utf-8 -*-
class Course < ActiveRecord::Base
  belongs_to :meal
  belongs_to :menu
end

