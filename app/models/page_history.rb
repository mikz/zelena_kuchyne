class PageHistory < ActiveRecord::Base
  belongs_to :page
  
  validates_presence_of :url
  validates_uniqueness_of :url
end
