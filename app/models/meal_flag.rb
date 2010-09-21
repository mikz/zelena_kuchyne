class MealFlag < ActiveRecord::Base
  has_many :flagged_meals
  has_many :meals, :through => :flagged_meals
  
  
  
  def save_image image
    inpath = %{#{RAILS_ROOT}/tmp/upload/#{current_user.id}/#{image}}
    outpath = %{#{RAILS_ROOT}/public/pictures/meal_flags_#{self.id}.jpg}
    thpath = %{#{RAILS_ROOT}/public/pictures/meal_flag_#{self.id}.th.jpg}
    File.unlink outpath if File.exists? outpath
    File.unlink thpath if File.exists? thpath
    %x{convert #{inpath} -resize 30x30 #{thpath}}
    %x{mv #{inpath} #{outpath}}
    self.icon_path = "/pictures/meal_flag_#{@record.id}.th.jpg"
    self.save
  end
  
  class << self
    def all_in_dialy_menu
      find(:all, :conditions => ["in_dialy_menu = ?", true])
    end
  end
end