class ProductCategory < ActiveRecord::Base
  acts_as_nested_set
  has_many :categorized_products
  has_many :products, :through => :categorized_products, :order => "products.name ASC"
  
  def coll_name
    tabs = ""
    self.level.times { tabs += "\t" }
    return "#{tabs}#{self.name}"
  end
end
