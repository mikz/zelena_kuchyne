class Meal < Item
  set_table_name 'meals'
  has_many :menus, :through => :courses
  has_many :courses
  has_many :ingredients, :through => :recipes, :order => "ingredients.name ASC"
  has_many :recipes
  has_many :spices, :through => :used_spices, :order => "spices.name ASC"
  has_many :used_spices
  has_many :days
  has_many :scheduled_meals
  has_many :flagged_meals
  has_many :meal_flags, :through => :flagged_meals, :order => "meal_flags.name ASC"
  has_many :bundles
  has_many :stock
  belongs_to :meal_category
  alias_attribute :category, :meal_category
  
  def save_spices(used_spices)
    q = ''
    if !used_spices.nil?
      used_spices.each do |spice, value|
        case value
        when 'new'
          q += %{INSERT INTO used_spices(spice_id, meal_id) VALUES (#{spice.to_i}, #{self.id});\n}
        when 'drop'
          q += %{DELETE FROM used_spices WHERE spice_id = #{spice.to_i} AND meal_id = #{self.id};\n}
        end
      end # each
    
      self.connection.execute q
    end
  end
  def description
    read_profile(:description)
  end
  def discount_price options={}
    options[:meals] = true
    @discount_price = super options
  end

  def cost
    self.connection.select_value "SELECT cost FROM meals_view WHERE id = #{self.id}"
  end
  
  # used instead of set_primary_key to get rid of strange association errors
  def self.primary_key
    "id"
  end
  
  def id
    (v=@attributes[self.class.primary_key]) && (v.to_i rescue v ? 1 : 0)
  end
  
end
