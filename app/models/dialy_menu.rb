class DialyMenu < ActiveRecord::Base
  validates_uniqueness_of :date
  has_many :entries, :class_name => "DialyMenuEntry", :dependent => :delete_all, :include => {:category => :order}, :order => "#{MealCategoryOrder.table_name}.order_id"
  has_many :disabled, :class_name => "DialyMenuScheduled", :dependent => :delete_all
  after_save :save_entries
  
  def initialize *args
    super
    
    self.date ||= Date.today
    
    self
  end
  
  def scheduled
    @scheduled ||= ScheduledItem.all(:conditions => ["scheduled_for = ?", self.date])
  end
  
  def meals(all = true)
    Meal.all(:conditions => ["item_id IN (?) AND (? OR item_id NOT IN (?))", self.scheduled.collect{|s|s.item_id}, all, self.disabled_item_ids], :order => "#{MealCategoryOrder.table_name}.order_id ASC", :include => [:meal_category => :order])
  end
  
  def disabled_item_ids
    self.disabled.collect{|d| d.item_id}
  end
  def banned?(item_id)
    self.disabled.collect{ |d| d.item_id }.include?(item_id)
  end
  
  private
  def save_entries
    self.entries.collect{ |entry|
      entry.save
    }.all?
  end
end
