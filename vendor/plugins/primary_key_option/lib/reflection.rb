module ActiveRecord
  module Reflection
    class AssociationReflection < MacroReflection
      def derive_primary_key_name
        if macro == :belongs_to
          "#{options[:primary_key] || "#{name}_id"}"
        elsif options[:as]
          "#{options[:as]}_id"
        else
          active_record.name.foreign_key
        end
      end
    end
  end
end