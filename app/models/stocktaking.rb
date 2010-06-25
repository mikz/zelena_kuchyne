class Stocktaking < ActiveRecord::Base
  has_many :logs, :class_name => "IngredientsLogFromStocktakingEntry", :include => :ingredient, :order => "ingredients.name ASC"
  has_many :ingredient_consumptions
  after_create :create_ingredients_logs, :if => :ingredients?
  after_create :create_ingredients_consumptions
  validates_associated :logs, :ingredient_consumptions
  validates_uniqueness_of :date, :on => :create
  
  def validate
    if date > Date.today
      errors.add("date","maximální hodnota je: #{Date.today.to_s}")
    end
    validate_ingredients_consumptions if create_ingredient_consumptions
  end
  
  def create_ingredient_consumptions= val
    @create_ingredient_consumptions = !val.to_i.zero?
  end

  def create_ingredient_consumptions
    @create_ingredient_consumptions == true
  end
  
  def ingredients= ingredients
    @ingredients = {}
    ingredients.each_pair do |id, data|
      @ingredients[id.to_i] = {:current => data[:current].to_f, :diff => data[:real].to_f - data[:current].to_f, :real => data[:real].to_f, :ignore => !data[:ignore].blank?, :consumption => !data[:consumption].blank? } if !data[:diff].blank?
    end
  end
  
  def ingredients?
    !@ingredients.blank?
  end
  
  private
  def create_ingredients_logs
    sql = ""
    @ingredients.each_pair do |id, data|
      sql << "INSERT INTO #{IngredientsLogFromStocktakingEntry.table_name}(ingredient_id, day, amount, stocktaking_id) VALUES(#{id}, '#{Date.parse(self.date.to_s).to_s}', #{data[:diff]}, #{self.id});\n"
    end
    self.connection.execute sql unless sql.blank?
  end
  
  def last_stocktaking
    return @last_stocktaking unless @last_stocktaking.nil?
    @last_stocktaking = self.class.find :first, :conditions => ["date < ?",self.date], :order => "date DESC"
  end
  
  def balance
    @balance ||= {}
    return @balance unless @balance.empty?
    IngredientsLogEntry.balance(:day => last_stocktaking.date , :order => "ingredient_name ASC", :paginate => false).each do |log|
      @balance[log.ingredient_id] = log
    end if last_stocktaking && @balance.empty?
    @balance 
  end
  def cooked
    @cooked ||= {}
    return @cooked unless @cooked.empty?
    IngredientsLogEntry.view_sum([last_stocktaking.date, self.date]).each do |log|
      @cooked[log.ingredient_id] = log.amount.abs
    end if last_stocktaking && @cooked.empty?
    @cooked
  end
  
  def validate_ingredients_consumptions
    @ingredients.each_pair do |id, data|
      if(balance[id] && cooked[id] && !data[:ignore])
        consumption = (cooked[id] - data[:diff])/cooked[id]
        unless consumption > 0
          self.errors.add("ingredient_#{id}","ignore")
          self.errors.add("ingredient_#{id}","spotřebováno na vaření: #{cooked[id]}<br/>spotřeba suroviny: #{consumption}<br/>")
        end
      end
    end if @ingredients
  end
  def create_ingredients_consumptions
    sql = ""
    @ingredients.each_pair do |id, data|
      if(balance[id] && cooked[id] && !data[:ignore] && data[:consumption])
        sql << "INSERT INTO #{IngredientConsumption.table_name}(ingredient_id, stocktaking_id, consumption) VALUES(#{id}, #{self.id}, #{(cooked[id] - data[:diff])/cooked[id]});\n"
      end
    end if @ingredients
    self.connection.execute sql unless sql.blank?
  end
  
end