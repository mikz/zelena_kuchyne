class BundleComputed < Bundle
  set_primary_key 'id'
  set_table_name 'bundles_view'
  belongs_to :meal, :foreign_key => "meal_id", :class_name => "MealComputed"
  
  def save
    bundle = self.becomes(Bundle)
    self.changed.each { |attr|
      bundle.send "#{attr}_will_change!"
    }
    bundle.save
    self.reload
  end
  
  def update_attributes attrs
    self.becomes(Bundle).update_attributes attrs
    save
  end
  
  def cost
    self[:cost]
  end  
end