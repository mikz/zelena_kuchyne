module ActiveRecord
  module Associations
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      
      def create_has_many_reflection(association_id, options, &extension)
        options.assert_valid_keys(
          :class_name, :table_name, :foreign_key, :primary_key,
          :dependent,
          :select, :conditions, :include, :order, :group, :limit, :offset,
          :as, :through, :source, :source_type,
          :uniq,
          :finder_sql, :counter_sql,
          :before_add, :after_add, :before_remove, :after_remove,
          :extend, :readonly,
          :validate
        )
        options[:extend] = create_extension_modules(association_id, extension, options[:extend])
        create_reflection(:has_many, association_id, options, self)
      end
      
      def create_has_one_reflection(association_id, options)
        options.assert_valid_keys(
          :class_name, :foreign_key, :primary_key, :remote, :select, :conditions, :order, :include, :dependent, :counter_cache, :extend, :as, :readonly, :validate
        )

        create_reflection(:has_one, association_id, options, self)
      end
      
      def create_belongs_to_reflection(association_id, options)
        options.assert_valid_keys(
          :class_name, :foreign_key, :foreign_type, :primary_key, :remote, :select, :conditions, :include, :dependent,
          :counter_cache, :extend, :polymorphic, :readonly, :validate
        )

        reflection = create_reflection(:belongs_to, association_id, options, self)

        if options[:polymorphic]
          reflection.options[:foreign_type] ||= reflection.class_name.underscore + "_type"
        end

        reflection
      end

      
    end
  end
end