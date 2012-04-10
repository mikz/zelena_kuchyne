# -*- encoding : utf-8 -*-
module MealFlagHelper
  def flag_image(flag)
    image_tag flag.icon_path, :alt => flag.name, :title => flag.description, :class => "flag"
  end
end

