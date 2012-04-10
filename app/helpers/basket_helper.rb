# -*- encoding : utf-8 -*-
module BasketHelper
  
  def time_of_delivery_options(steps = @delivery[:steps], selected = nil, order = @basket )
    selected = selected.presence || order.deliver_at.strftime("%H:%M") if order
    steps.map{ |step|
      attrs = {:value => step.strftime("%H:%M")}
      attrs.merge! :selected => true if step.strftime("%H:%M") == selected
      content_tag :option, step.strftime("%H:%M"), attrs
    }.join
  end
end

