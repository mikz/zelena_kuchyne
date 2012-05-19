# -*- encoding : utf-8 -*-
class ScheduledMeal < ActiveRecord::Base
  include Invisibility

  belongs_to :meal
  belongs_to :day, :foreign_key => 'scheduled_for', :primary_key => "scheduled_for"
  
  # this is not really a primary key, as that is defined as (scheduled_for, meal_id),
  # but it succeeds at fooling active record long enough for us to pull data through association
  set_primary_key "oid"

  def kind
    :meal
  end
end

