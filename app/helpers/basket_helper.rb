module BasketHelper
  
  def time_of_delivery_options
    selected = false
    buff = ""
    @delivery[:steps].each do |step|
      select = true if step.strftime("%H:%M") == @basket.deliver_at.strftime("%H:%M") or step == @delivery[:steps].last and !selected
      buff += "<option value='#{step.strftime("%H:%M")}'#{" selected='selected'" if select }>#{step.strftime("%H:%M")}</option>"
      selected = true if select
    end
    buff
  end
end
