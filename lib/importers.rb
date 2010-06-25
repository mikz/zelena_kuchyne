module Importers
  class Base
    def initialize(file)
      @file = file
      @data = file.read
      @log = []
    end
    
    class ImportError < StandardError
    end
    
    def import; end
  end

  class UsersFromCsv < Base
    require "csv"

    def import
      
      rows = []
      CSV::parse(@data) { |row|
        row.map!{ |cell|
          unless cell.nil?
            CSV::Cell.new(cell.data.strip)
          end
        }
        rows << row
      }
      valid_users = []
      invalid_users = []
      @log =[]
      map = indexes
      output = ""
      CSV::Writer.generate(output) do |csv|
        rows.delete_at(0)
        csv << [nil] + rows.delete_at(0)
        for row in rows
          data = populate_hash(map, row)
          data = fix_home_address(data)
          data = fix_delivery_address(data)
          data = fix_company_name(data)
          data = fix_phone_number(data)
          data = fix_company_tax_no(data)
          data = fix_company_registration_no(data)
          data = fix_tomorrow_menu_by_mail(data)
          user = User.new(data)
          user.imported_orders_price = data[:imported_orders_price]
          begin
            user.save!
            valid_users << user
            if(row[30].to_i > 0)
              user.user_discounts.create(:amount => row[30].to_i, :name => "sleva ze starého systému", :discount_class => "meal", :start_at => Date.today)
            end
          rescue
            @log << {:error => $!.inspect, :data => data, :user => user}
            invalid_users << user
            csv << [$!.to_s.gsub("Validation failed: ","")] + row
          end
        end
      end
      
      @log.each do |error|
        STDERR << %{
          error: #{error[:error]}
          data: #{error[:data].to_json}
        }
      end
      
      STDERR << %{
        Records: #{rows.size}
        Errors: #{@log.size}
      }
      
      return output
    end
    
    protected
    
    def fix_tomorrow_menu_by_mail data
      data[:tomorrow_menu_by_mail] = true
      data
    end
    
    def fix_company_tax_no data
      if data[:company_tax_no]
        data[:company_tax_no].upcase!
        data[:company_tax_no] = data[:company_tax_no].gsub(/\s/,"")
      end
      data
    end
    
    def fix_company_registration_no data
      if data[:company_registration_no]
        data[:company_registration_no] = data[:company_registration_no].gsub(/\s/,"")
      end
      data
    end
    
    def fix_home_address(data)
      ha = data[:home_address]
      if ha[:first_name].nil? and ha[:family_name].nil? and ha[:company_name].nil?
        ha[:first_name] = data[:first_name]
        ha[:family_name] = data[:family_name]
        ha[:company_name] = data[:company_name]
      end
      ha[:fixme] = true
      data[:home_address] = ha
      data
    end
    
    def fix_phone_number(data)
      if data[:phone_number]
        data[:phone_number] = data[:phone_number].scan(/(\d+)+/).join.to_i
      end
      data
    end
    
    def fix_delivery_address(data)
      activate = false
      data[:delivery_address].each_pair do |key,value|
        activate = true unless value.nil?
      end
      if activate
        data[:delivery_address][:first_name] ||= data[:home_address][:first_name] if !data[:delivery_address][:company_name]
        data[:delivery_address][:family_name] ||= data[:home_address][:family_name] if !data[:delivery_address][:company_name]
        data[:delivery_address][:company_name] ||= data[:home_address][:company_name] if !data[:delivery_address][:first_name] && !data[:delivery_address][:family_name]
        data[:delivery_address][:city] ||= "Praha"
        data[:delivery_address][:fixme] = true
      end
      data[:activate_delivery_address] = activate
      data
    end
    
    def fix_company_name data
      if data[:company_name] and !data[:company_registration_no]
        unless data[:activate_delivery_address]
          data[:delivery_address] = data[:home_address]
          if !data[:delivery_address][:company_name] or data[:delivery_address][:company_name] == data[:company_name]
            data[:delivery_address][:company_name] = data[:company_name]
          else
            data[:delivery_address][:note] = data[:company_name]
          end
        else
          data[:home_address][:note] = data[:home_address][:note] || "" + data[:company_name]
        end
        data[:company_name] = nil
      end
      data
    end
    
    def populate_hash(map, data)
      hash = {}
      map.each do |key, index|
        if(index.is_a?(Hash))
          hash[key] = populate_hash(index, data)
        else
          hash[key] = data[index]
        end
      end
      
      return hash
    end
    
    def indexes
      {
        :password => 31,
        :password_confirmation => 31,
        :login => 0,
        :email => 1,
        :first_name => 2,
        :family_name => 3,
        :company_name => 4,
        :company_registration_no => 5,
        :company_tax_no => 6,
        :phone_number_country_code => 7,
        :phone_number => 8,
        :home_address => {
          :first_name => 9,
          :family_name => 10,
          :company_name => 11,
          :street => 12,
          :house_no => 13,
          :city => 14,
          :district => 15,
          :zip => 16,
          :note => 17
        },
        :delivery_address => {
          :first_name => 18,
          :family_name => 19,
          :company_name => 20,
          :street => 21,
          :house_no => 22,
          :city => 23,
          :district => 24,
          :zip => 25,
          :note => 26
        },
        :imported_orders_price => 28
      }
    end
  end

  class CountryCodesFromText < Base
    class BadFormatError < ImportError
    end
    
    def import
      rows = @data.split("\n")
      rows.each { |row|
        data = row.split "\t"
        numbers = data.last.split ", "
        if numbers.length > 1
          for number in numbers
            begin
              CountryCode.create!(:name => "#{data.first} #{numbers.index(number) + 1}", :code => number)
            rescue
              @log << {:error => $!.to_s, :data => data}
            end
          end
        else
          begin
            CountryCode.create!(:name => data.first, :code => data.last)
          rescue
             @log << {:error => $!.to_s, :data => data}
           end
        end
      }
      STDERR << %{
        Errors:
      }

      @log.each { |error|
        STDERR << %{
          error: #{error[:error]}
          data: #{error[:data].to_json}
        }
      }
      raise 'finished'
    end
  end
  
  class UsersFromMysql < Base
    class BadLoginError < ImportError
    end
    
    class BadStreetNameError < ImportError
    end
    
    def import
      # Extract data using black magic
      rows = @data.split(/INSERT INTO [`'"]?#{table_name}[`'"]?[ ]+\(.+\)[ ]+VALUES\n/)
      rows.delete_at(0)
      rows = rows.map do |row|
        row.split("\n")
      end.flatten
      rows.delete_if do |row|
        !(row =~ /^\(.+\),$/)
      end
      rows = rows.map do |row|
        row.scan(/\'(.*?)\'/).map do |match|
          match.to_s
        end
      end
      
      # Import data
      users = []
      map = indexes
      rows.each do |row|
        begin
          data = fix_data(populate_hash(map, row))
        rescue ImportError
        else
          begin
            users << User.create(data)
          rescue
            @log << {:error => $!.to_s, :data => data}
          end
        end
      end
      
      STDERR << %{
        Errors:
      }
      
      @log.each do |error|
        STDERR << %{
          error: #{error[:error]}
          data: #{error[:data].to_json}
        }
      end
      
      raise 'stop'
    end
    
    protected
    
    # Extracts information from the original broken format and maps it onto our table structure...
    # ... or dies trying.
    def fix_data(data)
      methods = [:fix_login, :fix_address, :fix_streets, :fix_district]
      error_state = false
      methods.each do |method|
        begin
          data = self.send(method, data)
        rescue ImportError
          error_state = true
        end
      end
      
      if(error_state)
        raise ImportError
      else
        data
      end
    end
    
    def fix_district(data)
      city_with_number_and_district = /([a-zA-Z ]+)([0-9]+)[ \-\\\/]+([a-zA-Z ]+)/
      city_with_number = /([a-zA-Z ]+)([0-9]+)/
      city_with_district = /([a-zA-Z ]+)[ \-\\\/]+([a-zA-Z ]+)/
      proc = Proc.new do |city|
        if(match = city_with_number_and_district.match(city))
          [match[1], "#{match[1]} #{match[2]} - #{match[3]}"]
        elsif(match = city_with_number.match(city))
          [match[1], "#{match[1]} #{match[2]}"]
        elsif(match = city_with_district.match(city))
          [match[1], match[2]]
        else
          [city, city]
        end
      end
      
      whitespace = /([0-9]+) ([0-9]+)/
      proc_remove_whitespace = Proc.new do |city|
        city.gsub(whitespace, '\1\2')
      end
      
      data[:home_address][:city] = proc_remove_whitespace.call(data[:home_address][:city])
      if(data[:delivery_address])
        data[:delivery_address][:city] = proc_remove_whitespace.call(data[:delivery_address][:city])
      end
      
      data[:home_address][:city], data[:home_address][:district] = proc.call(data[:home_address][:city])
      if(data[:delivery_address])
        data[:delivery_address][:city], data[:delivery_address][:district] = proc.call(data[:delivery_address][:city])
      end
      
      return data
    end
    
    def fix_streets(data)
      no_pattern = /[0-9]+[\/\\]?[0-9]*[a-zA-Z]?/
      proc = Proc.new do |street|
        parts = street.split(' ')
        house_no = parts.last
        street = parts[0..-2].join(' ')
        unless house_no =~ no_pattern
          @log << {:error => 'bad_street_name', :data => data}
          raise BadStreetNameError
        end
        
        [street, house_no]
      end
      
      data[:home_address][:street], data[:home_address][:house_no] = proc.call(data[:home_address][:street])
      if(data[:delivery_address])
        data[:delivery_address][:street], data[:delivery_address][:house_no] = proc.call(data[:delivery_address][:street])
      end
      
      return data
    end
    
    def fix_address(data)
      deliv = data[:delivery_address]
      unless(deliv[:street].to_s != '' and deliv[:city].to_s != '' and deliv[:zip].to_s != '')
        data.delete(:delivery_address)
      end
      
      return data
    end
    
    def fix_login(data)
      replacements = {
        'á' => 'a',
        'ä' => 'a',
        'č' => 'c',
        'ď' => 'd',
        'é' => 'e',
        'ě' => 'e',
        'í' => 'i',
        'l' => 'l',
        'ľ' => 'l',
        'ĺ' => 'l',
        'ň' => 'n',
        'ó' => 'o',
        'ô' => 'o',
        'ř' => 'r',
        'ŕ' => 'r',
        'š' => 's',
        'ť' => 't',
        'ú' => 'u',
        'ů' => 'u',
        'ý' => 'y',
        'ž' => 'z',
        ' ' => '_',
        '-' => '_'
      }
      
      allowed = /^[a-z0-9_\.]+$/
      
      login = data[:login].chars.downcase
      replacements.each do |weird, normal|
        login.gsub!(weird, normal)
      end
      
      unless(login =~ allowed)
        @log << {:error => 'bad_login', :data => data}
        raise BadLoginError
      else
        data[:login] = login.to_s
        return data
      end
    end
    
    def populate_hash(map, data)
      hash = {}
      map.each do |key, index|
        if(index.is_a?(Hash))
          hash[key] = populate_hash(index, data)
        else
          hash[key] = data[index]
        end
      end
      
      return hash
    end
    
    def indexes
      {
        :password => 2,
        :password_confirmation => 2,
        :login => 0,
        :first_name => 3,
        :family_name => 4,
        :email => 5,
        :phone_number => 6,
        :home_address => {
          :street => 7,
          :zip => 9,
          :city => 8
        },
        :delivery_address => {
          :street => 13,
          :city => 14,
          :zip => 15,
          :first_name => 11,
          :family_name => 12
        }
      }
    end
    
    def table_name
      'uzivatele'
    end
  end
end