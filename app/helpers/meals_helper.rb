module MealsHelper
  def like_meal(meal)
    content_tag "fb:like", nil, :href => url_for(:controller => :meals, :action => :show, :id => meal.id, :only_path => false), "show-faces" => 'false', :layout => "standard", :action => "recommend", :font => "arial", :width => 430, :class => "fb_like"
  end
  
  def meal_flags(meal, only_path = true)
    meal.meal_flags.collect { |flag|
      image_tag url_for(:controller => flag.icon_path, :only_path => only_path), :class => :meal_flag, :alt => flag.name, :title => flag.description
    }.join
  end
end
