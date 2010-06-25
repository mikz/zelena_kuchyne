# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_error_details?
    ENV["RAILS_ENV"] != "production"
  end
  
  def smart_link(text, url_options = {}, options = {})
    options[:html] ||= {}
    options[:html].store(:href,url_for(url_options))
    options[:url] = url_options
    link_to_remote text, options
  end
  
  def format(value, options = {})
    options ||= {}   
    formatter = "format_#{(options[:formatter])? options[:formatter] : value.class.to_s.underscore}"    
    if respond_to? formatter
      return send(formatter, value, options)
    else
      value
    end
  end
  
  def format_interval(value, options = {})
    options ||= {}
    case value
      when nil
        locales['unknown_f']
      when 0
        locales['immediately']
      when 1
        locales['1_day']
      when 2..4
        locales['2to4_days'].sub "%n", (value.seconds / (24*60*60)).to_s
      else
        locales['x_days'].sub "%n", (value.seconds / (24*60*60)).to_s
    end
  end
  
  def format_distance(value, options ={})
    "#{format_numeric(value,options)}#{locales[:distance_unit]}"
  end
  
  def format_numeric(value, options = {})
    number = value.to_f
    
    options[:precision] ||= 3
    options[:delimiter] ||= ','
    options[:separator] ||= '&nbsp;'
    options[:fixed_length] ||= false
    options[:fixed_delimiter] ||= " "
    options[:precision_unit] ||= nil
    base = 10 # Yeah, we... pretty much assume that the base is ten.
    
    if options[:precision]
      q = base ** options[:precision]
      number = number * q
      number = number.round.to_f
      number = number / q
    end
    
    if options[:precision_unit]
      number = number / options[:precision_unit]
      number = number.round.to_f
      number = number * options[:precision_unit]
    end
    
    parts = number.to_s.split('.')
    parts.first.gsub!(/(\d)(?=(\d{3})+(?!\d))/, "\\1#{options[:separator]}")
    
    if(parts.last == '0')
      if options[:fixed_length]
        parts.first + options[:fixed_delimiter]*(options[:precision]+options[:delimiter].length)
      else
        parts.first
      end
    else
      if options[:fixed_length]
        parts.join(options[:delimiter]) + options[:fixed_delimiter]*(options[:precision] - parts.last.length)
      else
        parts.join(options[:delimiter])
      end
    end
  end
  
  alias format_float format_numeric
  alias format_fixnum format_numeric
  alias formar_bignum format_numeric
  
  def format_currency(value, options = {})
    template = options[:template] || locales[:currency] 
    number = format_numeric(value, options.merge({:precision => 2}))
    return template.gsub('%number', number)
  end
  
  def format_date(value, options = {})
    template = options[:template] || locales[:date]
    return template.gsub('%day', value.day.to_s).gsub('%month_name', locales["month_#{value.month}"]).gsub('%month', value.month.to_s).gsub('%year', value.year.to_s)
  end
  
  def format_date_with_weekday(value, options={})
    template = options[:template] || locales[:date_with_weekday]
    return template.gsub('%weekday',locales['weekdays'][value.wday-1]).gsub('%day', value.day.to_s).gsub('%month_name', locales["month_#{value.month}"]).gsub('%month', value.month.to_s).gsub('%year', value.year.to_s)
  end
  
  def format_time(value, options = {})
    template = options[:template] || locales[:time]
    flag = value.hour > 12 ? 'PM' : 'AM'
    hour12 = (flag == 'AM' ? value.hour : value.hour - 12).to_s
    hour12 = hour12.length == 1 ? hour12 = "0#{hour12}" : hour12
    hour24 = value.hour.to_s
    hour24 = hour24.length == 1 ? hour24 = "0#{hour24}" : hour24
    minute = value.min.to_s
    minute = minute.length == 1 ? minute = "0#{minute}" : minute
    return template.gsub('%24hour', hour24).gsub('%minute', minute).gsub('%flag', flag).gsub('%hour', hour12)
  end
  
  def format_nil_class(value, options = {})
    options[:template] || locales[:null]
  end
  
  def format_true_class(value, options = {})
    options[:template] || locales[:true]
  end
  
  def format_false_class(value, options = {})
    options[:template] || locales[:false]
  end
  
  def format_phone_number(phone_number, country_code=nil, options ={})
    phone_number_tpl = locales[:phone_number_template]
    country_code_tpl = locales[:country_code_template]
    country_code_out = country_code ? country_code_tpl.gsub("%cc",country_code) : nil
    
    phone_number_out = phone_number_tpl.clone
    phone_number.split(/(\d)/).each do |n|
      phone_number_out.sub!("%n",n.to_s) if !n.blank?
    end
    %{#{country_code_out + " " if country_code}#{phone_number_out}}
  end
  
  def format_date_and_time(value, options={})
    format = nil
    locales[:date_and_time].each {|f|
      format = f.first if f.last["hour"].include?(value.hour)
    }
    return format.sub("%date", format_date(value)).sub("%time", format_time(value))
  end
  
  def format_percent(value, options = {})
    return format_numeric(value*100) + " %"
  end
  
  def format_amount(value, options = {})
    unit = (options[:unit])? (locales.has_key?(options[:unit]))? locales[options[:unit]] : options[:unit]: locales[:amount_unit]  # if option :unit is locale key - use locales. if isn't - use it as string. else user locales[:amount_unit]
    return "#{format(value)} #{unit}"
  end
end
