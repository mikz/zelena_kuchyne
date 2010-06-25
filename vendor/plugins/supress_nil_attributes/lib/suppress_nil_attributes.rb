module SuppressNilAttributes
  def self.included(base) #:nodoc:
    base.class_eval "alias_method_chain :attributes_with_quotes, :suppress"
  end
  
  def attributes_with_quotes_with_suppress(include_primary_key = true, include_readonly_attributes = true, attribute_names = @attributes.keys)
    if self.new_record?
      attribute_names.delete_if do |attr|
        method = "#{attr}_changed?".to_sym
        if self.respond_to? method
          unless self.send(method)
            self[attr.to_sym].nil?
          end
        end
      end
      #if attribute_names.size != @attributes.keys.size
      #  self.class.class_eval "after_create Proc.new{|record| STDERR << %{\nRELOADING\n}\n; record.reload }"
      #end
    end
    attributes_with_quotes_without_suppress(include_primary_key, include_readonly_attributes, attribute_names)
  end
end