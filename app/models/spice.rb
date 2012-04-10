# -*- encoding : utf-8 -*-
class Spice < ActiveRecord::Base
  belongs_to :supplier
  has_many :used_spices
  has_many :meals, :through => :used_spices, :order => "meals.name ASC"
end

