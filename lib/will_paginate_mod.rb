module WillPaginateMod
  def self.included(base)
    ActionView::Base.send :include, WillPaginateDefaults
  end
  
  module WillPaginateDefaults
    
    def will_paginate(collection = nil, options = {})
      options.merge!({:next_label => LocalesSystem.locales['next_page'], :prev_label => LocalesSystem.locales['previous_page']})
      super(collection, options)
    end    
  end
end