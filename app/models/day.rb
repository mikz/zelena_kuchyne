# -*- encoding : utf-8 -*-
class Day < ActiveRecord::Base
  set_table_name 'days_view'
  set_primary_key 'scheduled_for'
  has_many :scheduled_meals, :foreign_key => 'scheduled_for'
  has_many :scheduled_menus, :foreign_key => 'scheduled_for'
  has_many :scheduled_bundles, :foreign_key => 'scheduled_for'
  has_many :meals, :through => :scheduled_meals
  has_many :menus, :through => :scheduled_menus
  has_many :bundles, :through => :scheduled_bundles
  has_many :stock, :foreign_key => "scheduled_for"
  

  class << self
    def between(from, to, invisible=false)
      self.find(:all, :conditions => ["scheduled_for BETWEEN ? AND ?", from, to], :invisible => invisible).collect {|day| day.scheduled_for }
    end
  
    private
    def validate_find_options(options) #:nodoc:
      options.assert_valid_keys(VALID_FIND_OPTIONS + [:invisible])
    end
  
    #overriding this method to load invisible scheduled meals and menus dates
    def find_every options={}
      if(options[:invisible])
        options[:from] = "get_days(true) days_view"
        options[:select] = "days_view AS scheduled_for"
      end
      super(options)
    end
  end
end

