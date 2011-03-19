# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def button_tag content = nil, options = {}, submit = true, &block
    options = {:type => "submit"}.merge(options) if submit
    content_tag :button, (block_given?)? block : content, options
  end
  
  def czech_typo(text)
    (h text).gsub(/(\s[ksvzouai])\s/i, '\\1&nbsp;').gsub(/\s([\-\–])/, '&nbsp;\\1')
  end
  
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
        t('unknown_f')
      when 0
        t('immediately')
      when 1
        t('1_day')
      when 2..4
        t('2to4_days').sub "%n", (value.seconds / (24*60*60)).to_s
      else
        t('x_days').sub "%n", (value.seconds / (24*60*60)).to_s
    end
  end
  
  def format_distance(value, options ={})
    "#{format_numeric(value,options)}#{t(:distance_unit)}"
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
    template = options[:template] || t(:currency) 
    number = format_numeric(value, options.merge({:precision => 2}))
    return template.gsub('{number}', number)
  end
  
  def format_date(value, options = {})
    l value.to_date
  end
  
  def format_date_with_weekday(value, options={})
    l value.to_date, :format => :with_day_abbr
  end
  
  def format_time(value, options = {})
    l value, :format => :very_short
  end
  
  def format_nil_class(value, options = {})
    options[:template] || t(:nil_class)
  end
  
  def format_true_class(value, options = {})
    options[:template] || t(:true_class)
  end
  
  def format_false_class(value, options = {})
    options[:template] || t(:false_class)
  end
  
  def format_phone_number(phone_number, country_code=nil, options ={})
    phone_number_tpl = t(:phone_number_template)
    country_code_tpl = t(:country_code_template)
    country_code_out = country_code ? country_code_tpl.gsub("%cc",country_code) : nil
    
    phone_number_out = phone_number_tpl.clone
    phone_number.split(/(\d)/).each do |n|
      phone_number_out.sub!("%n",n.to_s) if !n.blank?
    end
    %{#{country_code_out + " " if country_code}#{phone_number_out}}
  end
  
  def format_date_and_time(value, options={})
    l value
  end
  
  def format_percent(value, options = {})
    return format_numeric(value*100) + " %"
  end
  
  def format_amount(value, options = {})
    unit = if options[:unit]
      t options[:unit], :default => options[:unit]
    else
      t :amount_unit
    end
    
    return "#{format(value)} #{unit}"
  end
end
