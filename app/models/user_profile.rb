# -*- encoding : utf-8 -*-
class UserProfile < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_profile_type, :foreign_key => 'field_type'
end

