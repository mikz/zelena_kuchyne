# -*- encoding : utf-8 -*-
module ImagesHelper
  
  def item_image(item, th = true, host = true)
    url_field "/pictures/item_#{item.item_id}#{'.th' if th}.jpg", :only_path => !host
  end
end

