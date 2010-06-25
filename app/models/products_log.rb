class ProductsLog < ActiveRecord::Base
  belongs_to :product
  
  def self.days
    ProductsLogEntry.find(:all, :select => "DISTINCT day").collect{|entry| entry.day }
  end
  
  def self.all_days
    self.days + ProductsLogEntry.find_by_sql("SELECT DISTINCT deliver_at::date AS day FROM orders o LEFT JOIN ordered_items oi ON oi.order_id = o.id LEFT JOIN products p ON p.item_id = oi.item_id WHERE p.item_type IS NOT NULL").collect{|entry| entry.day }
  end

end