# -*- encoding : utf-8 -*-
class Group < ActiveRecord::Base
  has_many :users, :through => :memberships, :order => "users.name ASC"
  has_many :memberships
end

