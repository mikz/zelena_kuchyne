class OrderedItemView < OrderedItem
  belongs_to :order_view
  set_table_name 'ordered_items_view'
  
  has_one :real_record, :class_name => 'OrderedItem', :foreign_key => 'id'
  
  def discount_price options={}
    self.price * (1 - self.discount)
  end
end
