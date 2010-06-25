class LogbookCategory < ActiveRecord::Base
  has_many :entries, :class_name => "CarsLogbook"
  validates_length_of :name, :minimum => 1
end