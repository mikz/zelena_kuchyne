class OrderView < ActiveRecord::Base
  belongs_to :user
  belongs_to :delivery_man, :class_name => 'User', :foreign_key => 'delivery_man_id'
  has_many :ordered_items, :class_name => "OrderedItemView", :foreign_key => 'order_id', :include => [:item], :order => "items.name ASC"
  has_many :items, :through => :ordered_items, :order => "items.name ASC"
  belongs_to :order, :foreign_key => 'id', :include => [:delivery_method]
  belongs_to :delivery_method, :foreign_key => "delivery_method_id"
  has_many :possible_delivery_methods, :class_name => "DeliveryMethod", :finder_sql => 'SELECT * FROM delivery_methods WHERE minimal_order_price <= #{original_price || 0} AND zone_id = #{zone_id || "NULL"} ORDER BY price ASC;'
  
  set_table_name 'orders_view'
  
  has_one :real_record, :class_name => 'Order', :foreign_key => 'id'
  
  # returns summary price of closed and not cancelled orders for specified user 
  def self.sum_for_user user
    @sum_for_user = self.find(:first, :conditions => ["user_id = ? AND state = 'closed' AND cancelled = false", user.id], :select => "SUM(price) as price").price || 0.0
    @sum_for_user
  end

   def active_discounts
    @active_discounts ||= {}
    return @active_discounts if @active_discounts.size > 0
    ordered_item_item_ids = self.ordered_items.map {|oi| oi.item_id}
    ordered_items_classes = self.connection.select_values "SELECT DISTINCT discount_class FROM item_tables_view WHERE item_id IN (#{ordered_item_item_ids.join(',')});" if ordered_item_item_ids.size > 0
    @active_discounts[:user_discounts] = (UserDiscount.find :all, :conditions => ["user_id = ? AND discount_class IN (?) AND ?::date BETWEEN start_at AND COALESCE(expire_at, ?::date)", self.user_id, ordered_items_classes, self.deliver_at, self.deliver_at] if ordered_items_classes ) || []
    @active_discounts[:item_discounts] = ItemDiscount.find :all, :conditions => ["item_id IN (?) AND ?::date BETWEEN start_at AND COALESCE(expire_at, ?::date)", ordered_item_item_ids, self.deliver_at, self.deliver_at] || []
    @active_discounts[:wholesale_discounts] = WholesaleDiscount.find :all, :conditions => ["user_id = ? AND ?::date BETWEEN start_at AND COALESCE(expire_at, ?::date)", self.user_id, self.deliver_at, self.deliver_at] || []
    @active_discounts
  end
  
  def order_view
    self
  end
  
  def delivery_method_name
    self.delivery_method_without_autoload.name if self.delivery_method_without_autoload
  end
  def delivery_man_login
    self.delivery_man.login if self.delivery_man
  end
  def user_login
    self.user.login if self.user
  end
  
  def zone_id
    self.user.delivery_address.zone_id if self.user.delivery_address
  end
  
  
  def delivery_method_with_autoload
    self.order.delivery_method
  end
  alias_method_chain :delivery_method, :autoload
end
