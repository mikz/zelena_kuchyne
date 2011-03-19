module ToXlsMethods
  def to_xls(options = {})
    options.symbolize_keys!
    options.reverse_merge! :batch_size => 100
    
    output = '<?xml version="1.0" encoding="UTF-8"?><Workbook xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40" xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office"><Worksheet ss:Name="Sheet1"><Table>'
      
    if self.any?
      klass      = self.first.class
      attributes = self.first.attributes.keys.sort.map(&:to_sym)

      if options[:only]
        columns = Array(options[:only]) & attributes
      else
        columns = attributes - Array(options[:except])
      end

      columns += Array(options[:methods])

      if columns.any?
        unless options[:headers] == false
          output << "<Row>"
          columns.each { |column| output << "<Cell><Data ss:Type=\"String\">#{klass.human_attribute_name(column.to_s)}</Data></Cell>" }
          output << "</Row>"
        end
        
        yielder = lambda {|item|
          output << "<Row>"
          columns.each do |column|
            begin
              value = column.to_s.split(".").inject(item){ |item, method| item.send(method) }
            rescue
              value = nil
            end
            output << "<Cell><Data ss:Type=\"#{value.is_a?(Integer) ? 'Number' : 'String'}\">#{value}</Data></Cell>"
          end
          output << "</Row>"
        }
        
        
        if options[:batch_size] && self.respond_to?(:find_in_batches)
          self.find_in_batches :batch_size => options[:batch_size] do |array|
            array.each &yielder
          end
        else
          self.each &yielder
        end
      end
    end

    output << '</Table></Worksheet></Workbook>'
  end
end
