$(function(){
  parse_dates();  
  draw_month();
});

function parse_dates() {
  if(date = /\d{4}-\d{2}-\d{2}(\|\d{4}-\d{2}-\d{2})?/.exec(window.location)) {
    calendar_widget_selected_dates = date[0].split(';');
  }
}

function draw_month_today() {
  today = new Date();
  calendar_widget_year = today.getFullYear(); 
  calendar_widget_month = today.getMonth() + 1;
  
  $("#calendar_title").empty().prepend(calendar_widget_month_names[calendar_widget_month-1]+' '+calendar_widget_year);
  draw_month();
}

function draw_previous_month() {
  if(calendar_widget_month == 1) {
    calendar_widget_year -= 1; 
    calendar_widget_month = 13;
  }
  calendar_widget_month -= 1;

  $("#calendar_title").empty().prepend(calendar_widget_month_names[calendar_widget_month-1]+' '+calendar_widget_year);
  draw_month();
}

function draw_next_month() {
  if(calendar_widget_month == 12) {
    calendar_widget_year += 1; 
    calendar_widget_month = 0;
  }
  calendar_widget_month += 1;

  $("#calendar_title").empty().prepend(calendar_widget_month_names[calendar_widget_month-1]+' '+calendar_widget_year);
  draw_month();
}
function hasValInside(obj,val) {
    for(var i=0;i<obj.length;i++) {
        if (obj[i] == val)
            return i;
    }
    return -1;
}
function draw_month(week_starts_on) {
  if(typeof(window["calendar_widget_year"]) == "undefined" || typeof(window["calendar_widget_month"]) == "undefined") {
    return;
  }
  var first = true;
  var today = new Date();
  var date = ((calendar_widget_year != false && calendar_widget_month != false) ? new Date(calendar_widget_year, calendar_widget_month - 1, 1) : new Date(today.getFullYear(), today.getMonth(), 1));
  calendar_widget_year = date.getFullYear();
  calendar_widget_month = date.getMonth() + 1;
  week_starts_on = (week_starts_on == null ? 1 : week_starts_on % 7) // correct the weekday to start from 0
  var column = date.getDay() - week_starts_on;
  column < 0 ? column += 7 : false;
  
  // start the html
  var html = '<tr class="calendar_weekdays">';
  for(var i=0;i<calendar_widget_weekdays.length;i++) {
      html += "<td>"+ calendar_widget_weekdays[i]+"</td>";
  }
  html += "</tr><tr>"
  
  // before the month
  var day = new Date(date - column * 1000 * 60 * 60 * 24);
  while(day.getDate() != 1) {
    html += '<td class="calendar_inactive">'+day.getDate()+'</td>';
    day.setDate(day.getDate() + 1);
  }
  
  // the month
  month = day.getMonth();
  while(day.getMonth() == month) {
    if(day.getDay() == week_starts_on && !first ) {
        html += '</tr><tr>';
    }
    first = false;  
      
    datestring = day.getFullYear()+'-'+(day.getMonth() < 9 ? '0' : '')+(day.getMonth()+1)+'-'+(day.getDate() < 10 ? '0' : '')+(day.getDate());
    
    classes = [];
    if (day < today) {
        classes.push("calendar_passed");
    }
    
    if(day.getYear() == today.getYear() && day.getMonth() == today.getMonth() && day.getDate() == today.getDate()) {
      classes.push("calendar_today");
    }
    
    if(hasValInside(calendar_widget_selected_dates, datestring) >= 0) {
      classes.push("calendar_selected");
    }
    classstring = classes.length != 0 ? ' class="' + classes.join(' ') + '"' : "";
    
    html += '<td id="c_'+datestring+'"'+classstring+'>';

    if(hasValInside(calendar_widget_dates, datestring) >= 0)
      html += '<a href="#" onclick="calendar_widget_day_click(this, event, \''+datestring+'\'); return false;">'+day.getDate()+'</a>';
    else
      html += day.getDate();
  
    html += '</td>';
    day.setDate(day.getDate() + 1);
  } 
  
  // after the month
  if(week_starts_on != day.getDay()) {
    rest = week_starts_on - day.getDay();
    rest < 0 ? rest += 7 : false;
    
    while(rest-- > 0) {
      html += '<td class="calendar_inactive">'+day.getDate()+'</td>';
      day.setDate(day.getDate() + 1);
    }
  }
  
  html += "</tr>";
  $("#calendar_widget tbody").empty().prepend(html);
}

function calendar_widget_day_click(link, event, date) {
  $(calendar_widget_updates).empty().prepend('<p><img src="/images/loading.gif" alt="loading"/></p>');
  event.stopPropagation();
  
  if(hasValInside(calendar_widget_selected_dates,date) != -1) {
    $.ajax({
      type: "GET",
      url: calendar_widget_url.replace('__date__', '').replace('&amp;', '&'),
      dataType: "script"
    });
    $('table.calendar td').removeClass('calendar_selected');
    calendar_widget_selected_dates = [];
    return false;
  }
  
  if(event.shiftKey == 1 && calendar_widget_selected_dates.length == 1 && !calendar_widget_disable_range) {
    $.ajax({
      type: "GET",
      url: calendar_widget_url.replace('__date__', date+'~'+calendar_widget_selected_dates[0]).replace('&amp;', '&'),
      dataType: "script"
    });
    $('#c_'+date).addClass('calendar_selected');
    calendar_widget_selected_dates.push(date);
  } else {
    $.ajax({
      type: "GET",
      url: calendar_widget_url.replace('__date__', date).replace('&amp;', '&'),
      dataType: "script"
    });
    $('table.calendar td').removeClass('calendar_selected');
    $('#c_'+date).addClass('calendar_selected');
    calendar_widget_selected_dates = [date];
  }
  return false;
}