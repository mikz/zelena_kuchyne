# -*- encoding : utf-8 -*-
class Supplier < ActiveRecord::Base
  has_many :ingredients, :order => "ingredients.name ASC"
  has_many :spices, :order => "spices.name ASC"
end

