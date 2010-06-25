class Premise < ActiveRecord::Base
  validates_presence_of :name, :name_abbr, :address, :description
  validates_uniqueness_of :name_abbr
end