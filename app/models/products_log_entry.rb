class ProductsLogEntry < ActiveRecord::Base
  set_table_name 'products_log'

  belongs_to :product
  belongs_to :last_update_by, :class_name => 'User', :foreign_key => 'updated_by'

  before_save :set_updated_by
  after_create Proc.new {|r| r.reload }
  
  def self.days
    self.find(:all, :select => "DISTINCT day").collect{|entry| entry.day }
  end
  
  

  
  protected
  def set_updated_by
    self.last_update_by = UserSystem.current_user
    self.updated_at = Time.now
  end
  
  private
  def total_cost *args
    (args.empty?)? amount*product_cost : super
  end
end