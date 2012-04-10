# -*- encoding : utf-8 -*-
require "ostruct"

class MassMenu < OpenStruct
  def initialize(hash=nil)
    @table = {}
    if hash
      for k,v in hash
        v = MassMenu.new(v) if v.is_a?(Hash)
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
  end
    
  def [](key)
    @table[key.to_s.to_sym]
  end
  
  def new_ostruct_member(name)
    super(name.to_s)
  end
  
end

