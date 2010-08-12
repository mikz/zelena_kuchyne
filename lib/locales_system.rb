module LocalesSystem
  def self.included(base)
    self.extend(ClassMethods)
    
    languages = ['cs', 'en'] #TODO: move to configuration
    @locales = {}
    for language in languages
      path = "#{RAILS_ROOT}/config/locales/#{language}.yml"
      data = YAML::load(File.open(path))
      @locales[language] = LocalesHash.new data
    end
    
    base.helper_method :locales
  end
  
  # application-wide interface
  module ClassMethods
    def interface_language
      UserSystem.current_user.interface_language
    end
  
    def language_exists?(language)
      if @locales[language]
        true
      else
        false
      end
    end
  
    def locales
      return @locales[interface_language]
    end
  end
  
  # controller level interface
  def interface_language
    return LocalesSystem.interface_language
  end
  
  def language_exists?(language)
    return LocalesSystem.language_exists?(language)
  end
  
  def locales
    return LocalesSystem.locales
  end
  
  class LocalesHash
    def initialize(data)
      @hash = data
      @hash = {} unless @hash.is_a? Hash
      
      if(@hash.has_key? true)
        @hash['true'] = @hash[true]
      end
      
      if(@hash.has_key? false)
        @hash['false'] = @hash[false]
      end
    end
    
    def method_missing(method, *args)
      @hash.send method, *args
    end
    
    def has_key?(key)
      @hash.has_key? key.to_s.underscore
    end
    
    def [](*attrs)
      
      key = attrs.shift
      
      value = @hash[key.to_s.underscore]
      if(value == nil)
        "translation not found for: '#{key.to_s.underscore}'"
      else
        if attrs.empty?
          value
        elsif attrs.first.is_a? Hash
          attrs.first.each_pair do |name, replacement|
            value = value.gsub "{{#{name}}}", replacement
          end
          value
        else
          "bad parameters ( #{attrs.inspect} ) for translation: #{key.to_s.underscore}"
        end
      end
    end
  end
end


class ActiveRecord::Base
  def human_attribute_name(attribute_key_name) #:nodoc:
    attribute_key_name.to_s.humanize
  end
end