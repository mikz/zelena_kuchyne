# -*- encoding : utf-8 -*-

class News < ActiveRecord::Base
  validates_presence_of :publish_at
  
  def self.valid_news(options = {})
    options[:limit] ||= 5
    options[:order] ||= "publish_at DESC"
    @valid_news = self.find :all, :conditions => "publish_at < NOW() AND (expire_at > NOW() OR expire_at IS NULL)", :order => options[:order], :limit => options[:limit]
  end
  
  protected
  def validate
    if expire_at && expire_at < publish_at
      errors.add("expire_at","Datum konce musí být menší než začátku.")
    end
  end
end

