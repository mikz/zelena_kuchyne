# -*- encoding : utf-8 -*-
class Page < ActiveRecord::Base
  has_many :page_histories
  
  after_save :create_page_history
  before_save :check_editable
  attr_protected :editable
  protected
  def create_page_history
    if self.url_changed? 
      self.page_histories.create(:url => self.url_was) unless self.url_was.blank?
    end
  end
  
  def check_editable
    if !self.editable? && !self.editable_changed?
      raise UserSystem::AccessDenied
    end
  end
end

