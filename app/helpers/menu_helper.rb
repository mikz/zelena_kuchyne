# -*- encoding : utf-8 -*-
module MenuHelper
  def draw_calendar_switch(options = {})
    today = Date.today
    options[:date] ||= today
    options[:week_starts_on] ||= 1
    options[:scheduled_days] ||= [] 
    url_options = options[:url_options] ? options[:url_options] : {}
    date = options[:date]
    scheduled_days = options[:scheduled_days]
    weekdays = options[:weekdays] || t(:weekdays)
    calendar = '<table class="calendar">'
    column = date.beginning_of_month.wday - options[:week_starts_on]
    column += 7 if column < 0
  
    previous_day = today.beginning_of_month
    next_day = date + 10.years
    scheduled_days.each do |day|
      previous_day = day if day > previous_day and day < date.beginning_of_month
      next_day = day if day < next_day and day > date.end_of_month
    end
    next_day = next_day == (date + 10.years) ? nil : next_day
    previous_day = previous_day == today.beginning_of_month ? nil : previous_day
  
    # calendar header
  
    calendar << "<thead><tr><td>#{previous_day ? link_to('&lt;', :id => previous_day.strftime("%Y-%m-%d")) : '&lt;'}</td>"
    calendar << %{<td colspan="5">#{t("month_#{date.month}")} #{date.year.to_s}</td>}
    calendar << "<td>#{next_day ? link_to('&gt;', :id => next_day.strftime("%Y-%m-%d")) : '&gt;'}</td>"
    calendar << "</tr></thead><tbody>"
    calendar << %{<tr class="calendar_weekdays">}
    calendar << "<td>#{weekdays.join("</td><td>")}</td>"
    calendar << "</tr><tr>"
    
    # before the month
    prev_month = date.last_month
    last_day = prev_month.end_of_month
    day = last_day - column + 1
    while day <= last_day do
      calendar << "<td class=\"calendar_inactive\">#{day.day}</td>"
      day += 1
    end
  
    # the chosen month
    last_day =  [options[:last_day], date.end_of_month].compact.max
    day = date.beginning_of_month
    while day <= last_day do
     classes = []
     if day >= today
       day_s = scheduled_days.include?(day) ? link_to(day.day, url_options.merge(:id => day)) : day.day
       classes << "calendar_selected" if day == date
       classes << "calendar_today" if day == today 
     else
       day_s = day.day
       classes << "calendar_passed"
     end
     calendar << "<td #{classes ? "class=\"#{classes.join(" ")}\"" : ""}>#{day_s}</td>"
     
     day += 1
     column += 1
     if(column == 7)
       column = 0
       calendar << "</tr><tr>" unless day == last_day+1
     end
    end
    
      # after the month
    until column == 7 do
      calendar << "<td class=\"calendar_inactive\">#{day.day}</td>"
      day += 1
      column += 1
    end unless column == 0
  
    return "#{calendar}</tr></tbody></table>"
    end
end

