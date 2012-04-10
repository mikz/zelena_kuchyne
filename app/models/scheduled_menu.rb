# -*- encoding : utf-8 -*-
class ScheduledMenu < ActiveRecord::Base
  belongs_to :menu
  belongs_to :day, :foreign_key => 'scheduled_for', :primary_key => "scheduled_for"
  
  
  # scheduled_for is not really a primary key, as that is defined as (scheduled_for, meal_id),
  # but it succeeds at fooling active record long enough for us to pull data through association
  set_primary_key "oid"
  
  def set_amount_of_meal(meal, amount)
    create = []
    update = nil
    menu.meals.each do |m|
      if m.id != meal.id
        create.push m
      end
    end
    create.each do |m|
      scheduled = ScheduledMeal.find(:first, :conditions => ["scheduled_for = ? AND meal_id = ?", self.scheduled_for,  m.id])
      if scheduled
        scheduled.amount += self.amount - amount
        scheduled.save
      else
        ScheduledMeal.create!(:amount => self.amount - amount, :meal => m){|sm| sm.scheduled_for = self.scheduled_for } if self.amount - amount > 0
      end
    end
    self.amount = amount
    self.save!
  end
end

