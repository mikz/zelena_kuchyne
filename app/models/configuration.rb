class Configuration
  def self.method_missing(method, *args)
    if method.to_s.last == "="
      key = method.to_s.chop
      self.set_value key, args.first
    else
      key = method.to_sym
      self.values[key] ? self.values[key] : nil
    end
  end
  
  def self.values options={}
    if !defined? @@values
      self.update_values
    end
    @@values
  end
  
  # Returns Hash of delivery configuration options
  def self.delivery
    @delivery = {
      :from =>  Time.parse(self.delivery_from),
      :from_orig =>  self.delivery_from,
      :to => Time.parse(self.delivery_to),
      :to_orig => self.delivery_to,
      :step => self.delivery_step.to_i,
      :last => Time.parse(self.delivery_to) - 2*self.delivery_step.to_i
    }
    return @delivery
  end
  
  private
  def self.update_values options={}
    rows = ActiveRecord::Base.connection.select_all 'SELECT * FROM configuration;'
    @@values = {}
    for row in rows
      @@values[row['key'].to_sym] = row['value']
    end
  end
  
  def self.set_value(key,val)
    ActiveRecord::Base.connection.execute "UPDATE configuration SET value = #{ActiveRecord::Base.connection.quote(val)} WHERE key = #{ActiveRecord::Base.connection.quote(key)}"
    self.update_values
  end
end
