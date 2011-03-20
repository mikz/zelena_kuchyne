class MealCategoryOrder < ActiveRecord::Base
  set_table_name "meal_category_order"
  set_primary_key "category_id"
  belongs_to :category, :class_name => "MealCategory"
  
  validates_presence_of :order_id
  validates_uniqueness_of :order_id
  alias_attribute :order, :order_id
  
  before_validation :pick_order

  private
  def pick_order
    self.order ||= self.connection.select_value(%{SELECT MAX(order_id)+1 FROM #{self.class.table_name};}).to_i
  end
end
