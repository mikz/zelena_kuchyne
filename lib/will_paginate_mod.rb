# -*- encoding : utf-8 -*-
module WillPaginateMod
  def self.included(base)
    ActionView::Base.send :include, WillPaginateDefaults
  end
  
  module WillPaginateDefaults
    
    def will_paginate(collection = nil, options = {})
      options.merge!({:next_label => I18n.t('next_page'), :prev_label => I18n.t('previous_page')})
      super(collection, options)
    end    
  end
end

