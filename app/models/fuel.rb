class Fuel < ActiveRecord::Base
  set_table_name "fuel"
  belongs_to :user
  belongs_to :car
  belongs_to :last_update_by, :class_name => 'User', :foreign_key => 'updated_by'
  validates_presence_of :cost, :user, :amount
  validates_numericality_of :cost, :amount
  validates_length_of :note, :maximum => 100
  before_save :set_updated_by
  
  def user_login
    (self.user)? self.user.login : ""
  end
  
  def user_login= login
    self.user = User.find_by_login(login)
  end
  
  def validate

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
end