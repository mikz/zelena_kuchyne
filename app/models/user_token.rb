# -*- encoding : utf-8 -*-
class UserToken < ActiveRecord::Base
  belongs_to :user
end

