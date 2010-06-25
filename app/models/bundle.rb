class Bundle < Meal
  set_table_name 'bundles'
  belongs_to :meal
  has_many :scheduled_bundles
  
  def cost
    self.connection.select_value "SELECT cost FROM bundles_view WHERE id = #{self.id}"
  end
  
  # used instead of set_primary_key to get rid of strange association errors
  def self.primary_key
    "id"
  end
  
  def id
    (v=@attributes[self.class.primary_key]) && (v.to_i rescue v ? 1 : 0)
  end
end
