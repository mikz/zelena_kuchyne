# -*- encoding : utf-8 -*-
module ActiveRecord
  module Associations
    class HasOneAssociation < BelongsToAssociation #:nodoc:
      protected
      def quoted_id
        if @reflection.options[:primary_key]
          quote_value(@owner.send(@reflection.options[:primary_key]))
        else
          @owner.quoted_id
        end
      end
      
      private
        def construct_sql
          case
            when @reflection.options[:as]
              @finder_sql = 
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = #{quoted_id} AND " +
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = #{@owner.class.quote_value(@owner.class.base_class.name.to_s)}"
            else
              @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = #{quoted_id}"
          end
          @finder_sql << " AND (#{conditions})" if conditions
        end
        
    end
  end
end

