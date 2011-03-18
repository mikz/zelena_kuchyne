require 'to_xls'
Array.send :include, ToXlsMethods
ActiveRecord::NamedScope::Scope.send :include, ToXlsMethods
