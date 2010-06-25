class Product < Item
  set_table_name 'products'
  has_many :categorized_products
  has_many :product_categories, :through => :categorized_products, :order => "product_categories.name ASC"
  
  # used instead of set_primary_key to get rid of strange association errors
  def self.primary_key
    "id"
  end
  
  def id
    (v=@attributes[self.class.primary_key]) && (v.to_i rescue v ? 1 : 0)
  end
  
  def term_of_delivery= val
    val = nil if val == 'null' || val.empty?
    super(val)
  end
  
  def term_of_delivery
    days = term_of_delivery_days
    time = term_of_delivery_time
    interval = nil
    interval = interval.to_i + days.days if days
    interval = interval.to_i + time.sec.seconds + time.min.minutes + time.hour.hours if time
    interval
  end
  
  def term_of_delivery_time
    val = self[:term_of_delivery]
    time = /(\d{2}\:\d{2}\:\d{2})/.match(val)
    time = Time.parse(time[1]) if time
    (time)? time : nil
  end
  
  def term_of_delivery_days
    val = self[:term_of_delivery]
    days = /(\d+) days?/.match(val)
    days = days[1].to_i if days
    (days)? days : nil
  end
  
  def save_image image
    super(image,"78x78")
  end
end
