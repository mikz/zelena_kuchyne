class Zelenakuchyne < ActiveRecord::Base
  def self.export
    buffer = %{
      
    }
    models = [User, UserProfileType, UserProfile, Address, Group, Membership, Supplier, Ingredient, Spice, MealCategory, Meal, UsedSpice, Recipe, Menu, Course, Product, ProductCategory, CategorizedProduct, ItemProfileType, ItemProfile, MealFlag, FlaggedMeal, ScheduledMeal, ScheduledMenu, Order, OrderedItem, IngredientsLogEntry, News, Page, Snippet]

    buffer << export_models(models)
    buffer << export_sequences
    
    flush_tables = self.tables_from_sql buffer
    flush_tables.reverse!.map! { |t|
      "DELETE FROM #{t};"
    }
    sql = flush_tables.join("\r\n") << buffer
    sql
  end
  
  def self.import(sql)
    connection.execute(sql)
  end

  protected
  def self.export_model model, options={}
    columns = options[:columns] || model.columns_hash.keys
    records = model.find(:all)
    if records.size > 0
      sql = "-- #{model.to_s.pluralize.upcase}\r\nINSERT INTO #{model.table_name}(#{columns.join(',')}) VALUES"
      rows = []
      for record in records
        data = columns.map do |column|
          self.quote_value(record.send(column))
        end
        rows << "(#{data.join(',')})"
      end
    
      sql << rows.join(",\r\n")
      sql << ";\r\n"
    end
    sql = sql || ""
  end

  def self.tables_from_sql sql
    tables = sql.scan(/INSERT INTO (\w*)/).map! { |t|
      t.first
    }
    tables
  end
  
  def self.export_sequences
    schema = {}
    sql = ""
    rows = self.connection.select_all "SELECT * FROM information_schema.sequences;"
    for row in rows
      schema[row["sequence_name"]] = self.connection.select_value("SELECT last_value from #{row["sequence_name"]};")
    end
    schema.each_pair { |key,value|
      sql << "SELECT setval('#{key}',#{value});\r\n"
    }
    sql
  end
  
  def self.export_models models
    sql = ""
    models.each { |m|
      sql << self.export_model(m)
    }
    return sql
  end
  
end