# -*- encoding : utf-8 -*-
class DeliveryMethod < ActiveRecord::Base
  belongs_to :zone
  validates_uniqueness_of :name, :case_sensitive => false, :message => "Jméno již existuje. "
  validates_presence_of   :zone
end

