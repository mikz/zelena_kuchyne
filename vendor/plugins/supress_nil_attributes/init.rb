# -*- encoding : utf-8 -*-
require 'suppress_nil_attributes'

class ActiveRecord::Base
  include SuppressNilAttributes
end

