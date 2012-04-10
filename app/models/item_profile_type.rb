# -*- encoding : utf-8 -*-
class ItemProfileType < ActiveRecord::Base
  after_save :clean_cache
  after_destroy :clean_cache
  validates_uniqueness_of :name
  
  def clean_cache
    @cached_list = nil
  end
  
  def self.cached_list
    return @cached_list if @cached_list.present?
    entries = self.find(:all)
    @cached_list = {}
    for entry in entries
      @cached_list[entry.name] = entry.id
    end
    @cached_list.symbolize_keys!
    @cached_list
  end
  
  def self.cached_writers
    @cached_writers ||= cached_list.keys.map{|k| k + "="}
  end
  
  def self.cached_list=(cached_list)
    @cached_list = cached_list
  end
end

