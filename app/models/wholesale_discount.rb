# -*- encoding : utf-8 -*-
class WholesaleDiscount < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :start_at, :user, :discount_price
  validates_numericality_of :discount_price

  def validate
    wd = WholesaleDiscount.find :all, :conditions => ["user_id = ? AND ( ? BETWEEN start_at AND expire_at OR  ? BETWEEN start_at AND expire_at OR (expire_at IS NULL AND start_at > ? AND (? IS NULL OR start_at < ? ) ) )", self.user_id, self.start_at, self.expire_at, self.start_at, self.expire_at, self.expire_at]
    if wd.length > 0
      self.errors.add_to_base("Slevy se nemohou křižít. Smažte slevy:<br/> #{wd.map{|wd| "#{wd.user.login} | #{wd.discount_price} Kč | od: #{Date.parse(wd.start_at.to_s)} #{wd.note}" }.join(",<br/>")}")
    end
  end

  def user_login
    (self.user)? self.user.login : ""
  end
  
  def user_login= login
    self.user = User.find_by_login(login)
  end
end

