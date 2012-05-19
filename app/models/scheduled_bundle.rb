# -*- encoding : utf-8 -*-
class ScheduledBundle < ActiveRecord::Base
  include Invisibility

  belongs_to :bundle
  belongs_to :day, :foreign_key => 'scheduled_for', :primary_key => "scheduled_for"
  
  # this is not really a primary key, as that is defined as (scheduled_for, bundle_id),
  # but it succeeds at fooling active record long enough for us to pull data through association
  set_primary_key "oid"
  
  before_save :check_meal

  def amount
     @amount || (ScheduledMeal.find(:first, :conditions => ["scheduled_for = ? AND meal_id = ?", scheduled_for, bundle.meal_id]).amount/bundle.amount).floor
  end
  
  def amount=(val)
    @amount = val.to_i
    @amount
  end

  def reload_with_amount
    @amount = nil
    reload_without_amount
  end
  alias_method_chain :reload, :amount

  def kind
    :bundle
  end

  private
  
  def check_meal
    scheduled_meal = ScheduledMeal.find :all, :include => [:meal], :conditions => ["meals.item_id = ? AND scheduled_meals.scheduled_for = ?", self.bundle.meal.item_id, self.scheduled_for]
    if scheduled_meal.length > 0
      ScheduledMeal.update_all "amount = #{amount}*#{self.bundle.amount} ", ["scheduled_for = ? AND meal_id = ?", self.scheduled_for, self.bundle.meal.id]
    else
      ScheduledMeal.create(:meal => self.bundle.meal, :amount => self.amount * self.bundle.amount, :scheduled_for => self.scheduled_for )
    end
  end
end

