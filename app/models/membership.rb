# -*- encoding : utf-8 -*-
class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
end

