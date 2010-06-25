class Car < ActiveRecord::Base
  has_many :car_logbooks
  has_many :fuel
end