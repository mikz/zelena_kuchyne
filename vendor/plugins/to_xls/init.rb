# -*- encoding : utf-8 -*-
require 'to_xls'
Array.send :include, ToXlsMethods
ActiveRecord::NamedScope::Scope.send :include, ToXlsMethods

