class LostItem < ActiveRecord::Base
  set_primary_key 'oid'
  belongs_to :user
  belongs_to :item
  
  def validate

    current_user = UserSystem.current_user
    unless current_user.belongs_to_one_of?(:admins)
      errors.add("user", "this is not you") if self.user != UserSystem.current_user
    end
  end
  
end