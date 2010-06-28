module MealsHelper
  def like_meal(meal)
    content_tag "fb:like", nil, :href => url_for(:controller => :meals, :action => :show, :id => meal.id, :only_path => false), "show-faces" => 'false', :layout => "standard", :action => "recommend", :font => "arial", :width => 430, :class => "fb_like"
  end
end
