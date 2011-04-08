module ToXlsMethods
  def to_xls(options = {})
    options.symbolize_keys!
    options.reverse_merge! :batch_size => 100, :formatters => {Numeric => proc{|f|f.to_s.gsub(".",",")}}
    
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
      
      columns.map! {|column|
        case column
        when Hash
          column.map {|object, methods|
            methods.map {|method| 
              [object, method].join(".")
            }
          }
        else
          column
        end
          
      }
      columns.flatten!
      
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
              DEBUG {%w{column item}}
              value = column.to_s.split(".").inject(item){ |object, method| DEBUG {%w{object method}}; object.send(method) }
              DEBUG {%w{value}}
            rescue
              value = nil
            end
            
            formatted_value = value
            options[:formatters].each_pair do |klass, formatter|
              next unless value.is_a? klass
              formatted_value = formatter[value]
            end
            
            output << "<Cell><Data ss:Type=\"#{value.is_a?(Numeric) ? 'Number' : 'String'}\">#{formatted_value}</Data></Cell>"
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
