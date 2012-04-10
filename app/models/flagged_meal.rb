# -*- encoding : utf-8 -*-
class FlaggedMeal< ActiveRecord::Base
  set_primary_key 'oid'
  belongs_to :meal_flag
  belongs_to :meal
end

