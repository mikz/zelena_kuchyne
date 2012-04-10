# -*- encoding : utf-8 -*-
module ActiveRecord
  module Associations
    class HasManyAssociation < AssociationCollection  
      module ClassMethods
        
        protected
        def quoted_id
          if @reflection.options[:primary_key]
            quote_value(@owner.send(@reflection.options[:primary_key]))
          else
            @owner.quoted_id
          end
        end
        
        def delete_records(records)
          case @reflection.options[:dependent]
            when :destroy
              records.each(&:destroy)
            when :delete_all
              @reflection.klass.delete(records.map(&:id))
            else
              ids = quoted_record_ids(records)
              @reflection.klass.update_all(
                "#{@reflection.primary_key_name} = NULL", 
                "#{@reflection.primary_key_name} = #{quoted_id} AND #{@reflection.klass.primary_key} IN (#{ids})"
              )
          end
        end

        def construct_sql
          case
            when @reflection.options[:finder_sql]
              @finder_sql = interpolate_sql(@reflection.options[:finder_sql])

            when @reflection.options[:as]
              @finder_sql = 
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_id = #{quoted_id} AND " +
                "#{@reflection.quoted_table_name}.#{@reflection.options[:as]}_type = #{@owner.class.quote_value(@owner.class.base_class.name.to_s)}"
              @finder_sql << " AND (#{conditions})" if conditions
    
            else
              @finder_sql = "#{@reflection.quoted_table_name}.#{@reflection.primary_key_name} = #{quoted_id}"
              @finder_sql << " AND (#{conditions})" if conditions
          end

          if @reflection.options[:counter_sql]
            @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
          elsif @reflection.options[:finder_sql]
            # replace the SELECT clause with COUNT(*), preserving any hints within /* ... */
            @reflection.options[:counter_sql] = @reflection.options[:finder_sql].sub(/SELECT (\/\*.*?\*\/ )?(.*)\bFROM\b/im) { "SELECT #{$1}COUNT(*) FROM" }
            @counter_sql = interpolate_sql(@reflection.options[:counter_sql])
          else
            @counter_sql = @finder_sql
          end
        end
  
      end
    end
  end
end

