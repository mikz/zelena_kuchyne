class UsedSpice < ActiveRecord::Base
  belongs_to :meal
  belongs_to :spice
end
