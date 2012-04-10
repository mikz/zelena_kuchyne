# -*- encoding : utf-8 -*-
class UserDiscount < ActiveRecord::Base
  set_table_name 'user_discounts'
  belongs_to :user
  validates_presence_of :user,:name,:amount
  
  def validate   
    ud = UserDiscount.find :all, :conditions => ["user_id = ? AND discount_class = ? AND ( ? BETWEEN start_at AND expire_at OR  ? BETWEEN start_at AND expire_at OR (expire_at IS NULL AND start_at > ? AND (? IS NULL OR start_at < ? ) ) )", self.user_id, self.discount_class, self.start_at, self.expire_at, self.start_at, self.expire_at, self.expire_at]
    if ud.length > 0
      self.errors.add_to_base("Slevy se nemohou křižít. Smažte slevy:<br/> #{ud.map{|ud| "#{ud.user.login} - #{ud.name} - #{ud.amount}%" }.join(",<br/>")}")
    end
  end
  
  def amount
    super*100
  end
  
  def amount= value
    self[:amount] = value.to_f/100
  end

  def destroy
    unless new_record?
      ret = connection.delete "DELETE FROM #{self.class.quoted_table_name} WHERE #{connection.quote_column_name(self.class.primary_key)} = #{connection.quote(self.id)}\n", "#{self.class.name} Destroy"
    end
    freeze unless ret == 0
    return ret || 0
  end
  
end

