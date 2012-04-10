# -*- encoding : utf-8 -*-
class SoldItem < ActiveRecord::Base
  set_primary_key 'oid'
  belongs_to :item
  belongs_to :user
  
  def validate
    current_user = UserSystem.current_user
    unless current_user.belongs_to_one_of?(:admins)
      errors.add("user", "this is not you") if self.user != UserSystem.current_user
    end
  end
end

