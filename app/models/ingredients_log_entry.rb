class IngredientsLogEntry < ActiveRecord::Base
  belongs_to :ingredient
  validates_presence_of :ingredient_id, :day, :amount
  
  set_table_name 'ingredients_log'
  
  def self.days
    day = self.find_by_sql "SELECT day FROM ingredients_log GROUP BY day"
    @days = day.collect { |day| day.day }
  end
  
  def self.balance options={}
    sql = "SELECT ingredient_id, SUM(amount) as amount, i.name as ingredient_name, i.unit as ingredient_unit FROM ingredients_log_full_view LEFT JOIN ingredients i ON i.id = ingredient_id #{(options[:day].blank?)? '' : "WHERE day <= '#{options[:day]}' "} GROUP BY ingredient_id, ingredient_name, ingredient_unit #{(options[:order].blank?)? '' : "ORDER BY "+options[:order]}"
    if (options[:paginate] == false) 
      @balance = self.find_by_sql sql
    else
      @balance = self.paginate_by_sql sql, :page => options[:page] 
    end
  end
  
  def self.balance_days
    day = self.find_by_sql "SELECT day FROM ingredients_log_full_view GROUP BY day"
    @balance_days = day.collect { |day| day.day }
  end
  
  def self.full_log_per_day options={}
    @full_log_per_day = self.paginate_by_sql "SELECT l.*, i.name as ingredient_name, i.unit as ingredient_unit FROM ingredients_full_log_per_day_view l LEFT JOIN ingredients i ON i.id = ingredient_id #{(options[:conditions].blank?)? '' : "WHERE #{options[:conditions].join(" AND ")} "} #{(options[:order].blank?)? '' : "ORDER BY "+options[:order]}", :page => options[:page]
  end
  
  def self.full_log_per_meal options={}
    @full_log_per_meal = self.paginate_by_sql "SELECT l.*, i.name as ingredient_name, i.unit as ingredient_unit FROM ingredients_full_log_per_meal_view l LEFT JOIN ingredients i ON i.id = ingredient_id #{(options[:conditions].blank?)? '' : "WHERE #{options[:conditions].join(" AND ")} "} #{(options[:order].blank?)? '' : "ORDER BY "+options[:order]}", :page => options[:page]
  end
  
  def self.full_log_days
    day = self.find_by_sql "SELECT day FROM ingredients_full_log_per_day_view GROUP BY day"
    @full_log_days = day.collect { |day| day.day }
  end
  
  def self.view_sum dates
    @view = self.find_by_sql "SELECT ingredient_id, SUM(amount) AS amount FROM ingredients_log_view WHERE day BETWEEN '#{Date.parse(dates[0].to_s)}' AND '#{Date.parse(dates[1].to_s)}' GROUP BY ingredient_id;"
  end

  def self.owners
    ["delivery","restaurant"].collect { |item|
      [LocalesSystem.locales["ingredients_log_owner_#{item}"], item]
    }
  end
end
