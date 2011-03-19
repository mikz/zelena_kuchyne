class UserProfileType < ActiveRecord::Base
  after_save :clean_cache
  after_destroy :clean_cache
  validates_uniqueness_of :name
  
  def clean_cache
    @cached_list = nil
  end
  
  def self.cached_list
    return @cached_list if(@cached_list)
    entries = self.find(:all)
    @cached_list = {}
    for entry in entries
      @cached_list[entry.name] = entry.id
    end
    @cached_list.symbolize_keys!
    @cached_list
  end
  
  def self.cached_list=(cached_list)
    @cached_list = cached_list
  end
end
