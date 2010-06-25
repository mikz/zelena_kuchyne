module FilterWidget
  
  def self.included(base)
    base.helper_method :filter_widget
    base.include_javascripts 'filter_widget'
    base.include_stylesheets 'filter_widget'
  end
  
  def filter_widget_conditions(filters)
    conditions = []
    filters.each do |filter|
      raise ActiveRecord::StatementInvalid, 'column name cannot include spaces' if filter['attr'].include?(' ')
      if filter['value'] == "null"
        conditions.push("#{filter['attr']} IS NULL")
      else
        conditions.push("#{filter['attr']} #{sql_op_for(filter['op'])} #{ActiveRecord::Base.quote_value(filter['value'])}")
      end
    end
    
    return conditions.join(" AND ")
  end
  
  def filter_widget(id, options, &block)
    wrap = options[:wrap] or true;
    options.delete(:wrap)
    
    result = ""
    result << '<script type="text/javascript">' if wrap
    result << '$(function() {'
    result << %{filterWidget("#{id}", #{RuleGenerator.hash_to_js_object(options)});\n}
    result << yield(RuleGenerator.new(id)).to_s
    result << %{filterWidget("#{id}").addRuleLine();}
    result << '});'
    result << '</script>' if wrap
    
    return result
  end
  
  private 
  
  def sql_op_for(op)
    case(op)
    when "e":
      "="
    when "lt":
      "<"
    when "gt":
      ">"
    when "ltoe":
      "<="
    when "gtoe":
      ">="
    when "ne":
      "!="
    end
  end
  
  class RuleGenerator
    
    def initialize(widget_id)
      @widget_id = widget_id
    end
    
    def add_rule(name, label, type, values = {})
      @rules ||= []
      @rules.push({:name => name, :label => label, :type => type, :values => values})
      return self
    end
    
    def to_s
      result = ""
      @rules.each do |rule|
        result << %{filterWidget("#{@widget_id}").addRule("#{rule[:name]}", "#{rule[:label]}", "#{rule[:type]}"#{rule[:values] ? ", #{rule[:values].to_json}" : ""});\n}
      end
      
      return result
    end
    
    # dunno why to use this insted of hash.to_json
    def self.hash_to_js_object(hash)
      return "" unless hash.respond_to?(:each_pair)
      result = []
      hash.each do |key, value|
        if value =~ /^function/ 
          result << %{#{key}: #{value}}
        elsif value.is_a?(Hash)  
          result << %(#{key}: #{hash_to_js_object(value)})
        else
          result << %{#{key}: "#{value}"}
        end
      end
      
      return "{#{result.join(', ')}}"
    end
  end
end