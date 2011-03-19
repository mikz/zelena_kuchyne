class DialyMenu < ActiveRecord::Base
  validates_uniqueness_of :date
  has_many :entries, :class_name => "DialyMenuEntry", :dependent => :delete_all, :include => {:category => :order}, :order => "#{MealCategoryOrder.table_name}.order_id, in_menu DESC"
  
  before_create :copy_scheduled
  after_save :save_entries
  
  def initialize *args
    super
    
    self.date ||= Date.today
    
    self
  end
  
  def scheduled
    @scheduled ||= ScheduledItem.all(:conditions => ["scheduled_for = ?", self.date])
  end
  
  def meals
    Meal.all(:conditions => ["meals.item_id IN (?)", self.scheduled.collect(&:item_id) ], :order => "#{MealCategoryOrder.table_name}.order_id ASC", :include => [:meal_category => :order])
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
  
  def copy_scheduled
    DEBUG {%w{meals}}
    meals.each do |meal|
      self.entries.build :meal => meal
    end
  end
end
