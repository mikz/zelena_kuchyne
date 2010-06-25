require "#{RAILS_ROOT}/app/models/address.rb"

class Address
  def self.with_mapy_cz(&block)
    @@with_mapy_cz = true
    begin
      yield
    rescue Test::Unit::AssertionFailedError => a
      @@with_mapy_cz = false
      raise a
    end
    @@with_mapy_cz = false
  end
  
  def validate_with_mock
    @@with_mapy_cz ||= false
    return true unless @@with_mapy_cz
    
    validate_without_mock
  end
  
  alias_method_chain :validate, :mock
end