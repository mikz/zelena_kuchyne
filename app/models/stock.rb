# -*- encoding : utf-8 -*-
class Stock < ActiveRecord::Base
  belongs_to :meal
  set_table_name 'scheduled_meals_left_view'
end

