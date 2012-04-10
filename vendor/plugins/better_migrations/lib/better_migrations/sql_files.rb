# -*- encoding : utf-8 -*-
module BetterMigrations
  module SQLFiles
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def sql_script(name)
        adapter = adapter_name.downcase
        choices = ["#{name}.#{adapter}.sql", "#{name}.sql"]
        filename = nil
        choices.each do |f|
          path = "#{RAILS_ROOT}/db/sql/#{f}"
          if File.exist?(path)
            filename = path
            break;
          end
        end
        
        unless filename
          raise SQLFileNotFoundError, "Could't find definition for sql script \"#{name}\". Looked in #{choices.to_sentence}."
        else
          sql = File.open(filename, 'r') do |f|
            f.read
          end
          
          return execute(sql)
        end
      end
    end
  end
end

