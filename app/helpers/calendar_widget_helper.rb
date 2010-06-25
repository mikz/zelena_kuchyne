module CalendarWidgetHelper
  
  def calendar_widget(options = {})
    today = Date.today
    year = options[:year] || today.year
    month = options[:month] || today.month
    weekdays = options[:weekdays] || locales[:weekdays]
    
    args = params.clone
    args.merge!(options[:params] || {})
    args[:action] = options[:action] || 'show'
    args[options[:date_param] || :id] = "__date__"
    
    names = []
    1.upto 12 do |i|
      names.push(locales["month_#{i}"])
    end
    
    script = %{<script type="text/javascript">
      //<![CDATA[
      calendar_widget_url = '#{url_for(args).gsub("&amp;","&")}'
      calendar_widget_dates = ['#{options[:active_dates].join("', '")}'];
      calendar_widget_month_names = ['#{names.join("', '")}'];
      calendar_widget_year = #{options[:year] ? year : 'false'}; 
      calendar_widget_month = #{options[:date] ? month : 'false'};
      calendar_widget_selected_dates = [];
      calendar_widget_updates = '#{options[:updates]}';
      calendar_widget_weekdays = #{weekdays.to_json};
      calendar_widget_disable_range = #{options[:disable_range] || false};
      //]]>
    </script>}
    
    calendar = "<table class=\"calendar\" id=\"calendar_widget\">"
    calendar << "<thead><tr class=\"calendar_header\"><td><a href=\"#\" onclick=\"draw_previous_month(); return false;\">&lt;</a></td>"
    calendar << "<td colspan=\"5\" ><span id=\"calendar_title\">#{locales["month_#{month}"]} #{year}</span><br/><a href=\"#\" onclick=\"draw_month_today();\" id=\"calendar_back_to_today\">(dnes)</a></td>"
    calendar << "<td><a href=\"#\" onclick=\"draw_next_month(); return false;\">&gt;</a></td>"
    calendar << "</tr></thead>"
    calendar << "<tbody id=\"calendar_body\"><tr><td colspan=\"7\"/></tr></tbody></table>"
  
    return "#{script}#{calendar}"
  end
end
