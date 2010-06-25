class Menu < Item
  set_table_name 'menus'
  has_many :courses
  has_many :meals, :through => :courses, :order => "meals.name ASC"
  has_many :days
  has_many :scheduled_menus
  
  def discount_price options={}
    options[:meals] = true
    @discnout_price = super options
  end
  
  def cost
    self.connection.select_value "SELECT cost FROM menus_view WHERE id = #{self.id}"
  end
  
  # used instead of set_primary_key to get rid of strange association errors
  def self.primary_key
    "id"
  end
  
  def id
    (v=@attributes[self.class.primary_key]) && (v.to_i rescue v ? 1 : 0)
  end
end
