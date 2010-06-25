class ProductsLogBalanceView < ProductsLog
  belongs_to :product, :foreign_key => "product_id"
  set_table_name 'products_log_balance_view'
  set_primary_key 'product_id'
  
  def self.find_every options={}
    options[:select] ||= "product_id, SUM(amount) AS amount, MAX(day) AS day"
    options[:group]  ||= "product_id, products.name"
    options[:joins]   ||= "LEFT JOIN products ON products.id = product_id"
    super options
  end
  
  def product
    @product ||= self.class.products[self.product_id] || self.class.reload_products[self.product_id]
  end
  
  def self.preload_products ids
    @products ||= {}
    ProductWithStock.find(:all, :order => "name", :conditions => ["id IN (?)",ids]).each { |p|
      @products[p.id] = p
    }
  end
  
  def self.products
    return @products unless @products.nil?
    @products ||= {}
    ProductWithStock.find(:all, :order => "name").each { |p|
      @products[p.id] = p
    }
    return @products
  end
  
  def self.reload_products
    @products = nil
    products
  end
  
  def self.erase_products
    @products = nil
  end
end