class CarsLogbook < ActiveRecord::Base
  require "bigdecimal"
  
  set_table_name 'cars_logbooks'
  belongs_to :user
  belongs_to :car
  belongs_to :last_update_by, :class_name => 'User', :foreign_key => 'updated_by'
  before_save :set_updated_by
  validates_presence_of :date, :user
  validates_numericality_of :beginning_in_kilometers, :ending_in_kilometers, :private_distance_in_kilometers, :business_distance_in_kilometers
  validates_presence_of :logbook_category_id, :if => Proc.new {|l| l.business_distance > 0 }
  
  def method_missing(method, *args)
    if method.to_s =~ /_in_kilometers$/
      return to_kilometers(self[method.to_s.sub(/_in_kilometers$/,"").to_sym])
    elsif method.to_s =~ /_in_kilometers=$/
      return self[method.to_s.sub(/_in_kilometers=$/,"").to_sym] = to_meters(args[0])
    elsif method.to_s =~ /_in_kilometers_before_type_cast$/
      return self.send(method.to_s.sub(/_before_type_cast$/,""))
    else
      super
    end
  end
  
  def user_login
    (self.user)? self.user.login : ""
  end

  def user_login= login
    self.user = User.find_by_login(login)
  end

  def validate
    if (ending.to_i - beginning.to_i) != (private_distance.to_i + business_distance.to_i)
      msg = "distances are not equal"
      errors.add("beginning_in_kilometers", msg)
      errors.add("ending_in_kilometers", msg)
      errors.add("private_distance_in_kilometers", msg)
      errors.add("business_distance_in_kilometers", msg)
    end
    current_user = UserSystem.current_user
    current_user = UserSystem.current_user
    unless current_user.belongs_to_one_of?(:admins,:heads_of_car_pool)
      errors.add("user", "this is not you") if self.user != UserSystem.current_user
    end

    err = errors.clone
    errors.clear
    err.each do |attr,msg|
      attr += "_login" if attr == "user"
      errors.add(attr,msg)
    end
  end

  def destroy
    current_user = UserSystem.current_user
    if current_user == self.user || current_user.belongs_to_one_of?(:admins, :heads_of_car_pool)
      super
    end
  end
  
  def self.days
     self.connection.select_values "SELECT DISTINCT date FROM #{self.table_name};"
  end
  
  protected

  def set_updated_by
    self.last_update_by = UserSystem.current_user
  end
  
  def to_kilometers(meters)
    (meters.blank?)? nil : BigDecimal.new(meters.to_s)/1000
  end
  
  def to_meters(kilometers)
    (kilometers.blank?)? nil : (BigDecimal.new(kilometers.to_s)*1000).to_i
  end
end