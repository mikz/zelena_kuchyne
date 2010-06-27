class DeliveryMan < User
  has_many :orders_to_deliver, :class_name => "Order", :conditions => "delivery_man_id = \#{self.id}"
  has_many :items_to_load, :class_name => "ItemToLoad"
  
  def self.find *args
    options = args.extract_options!
    options[:include] ||= []
    options[:include] << {:groups => :memberships}
    option = " groups.system_name = 'deliverymen'"
    if options[:conditions].is_a?(Array)
      options[:conditions][0] = "#{options[:conditions].first} AND " + option
    elsif options[:conditions].is_a?(String)
      if options[:conditions].length > 0
        options[:conditions] += " AND "
      end
      options[:conditions] += option
    elsif options[:conditions].is_a?(NilClass)
      options[:conditions] = option
    end
    
    super(args.first, options)
  end
  
  def label
    self.last_name
  end
  
  def delivery_items date
    DeliveryItem.find :all, :conditions => ["scheduled_for::date =  ? AND delivery_man_id = ?",date,self.id], :include => [:item]
  end
  
  def orders_for_date date
    @orders_for_date = OrderView.find :all, :conditions => ["delivery_man_id = ? AND deliver_at::date = ? AND state IN ('order','expedited','closed') AND cancelled = false", self.id, date], :order => "deliver_at ASC, items.item_id DESC", :include => [{:ordered_items => :item }, :user ]
  end
  
  def sum_price date
    @sum_price = OrderView.find_by_sql("SELECT SUM(price) as price FROM orders_view WHERE cancelled = false AND delivery_man_id = '#{self.id}' AND deliver_at::date = '#{date}';").first
    if @sum_price
      return @sum_price = @sum_price.price
    else
      return 0
    end
  end
end