
var filterWidget = window.filterWidget = function(formID, options) {
  return new filterWidget.prototype.init(formID, options);
}

filterWidget.prototype = {
  
  types: ['boolean', 'string', 'numeric', 'enum', 'autocomplete'],

  options: {
    url: '',
    beforeSend: function() {},
    strings: {
      val_true: "true",
      val_false: "false",
      submit: "Submit Query",
      show_all: "Show all"
    }
  },
  
  init: function(form, options) {
    
    url = window.location.pathname;
    url = url.replace(/&amp;/g, '&');
    if(this.options.url.length == 0) {
      this.options.url = url;
    }

    if(typeof(form) == "string") {
      this.form = $("#"+form);
      var formID = form;
    } else {
      while(form.tagName != "FORM") {
        if(typeof(form.parentNode) == "undefined") {
          throw "Form element not found! (Called from outside of the form?)";
        }
        form = form.parentNode;
      }
      
      this.form = $(form);
      var formID = this.form.attr("id");
    }
    
    // if this is a first call on this element, build the form and store the empty set
    if(typeof(this.form.data("rules")) == "undefined") {
      $.extend(this.options, options);
      
      var formHtml = '<form id="'+formID+'" class="filter_widget" onsubmit="filterWidget(this).send(); return false;"><p class="filter_widget_submit"><input type="submit" value="'+ this.options.strings.submit +'" /><a href="#" onclick="filterWidget(this).reset(); return false;">'+  this.options.strings.show_all+'</a></p></form>';
      this.form.replaceWith(formHtml);
      this.form = $("#"+formID);
      
      
      this.form.data("rules", []);
      this.form.data("options", this.options);
    }
    
    this.rules = this.form.data("rules");
    this.options = this.form.data("options");
    return this;
  },
  
  updateOptions: function(options) {
    $.extend(this.options, options);
    this.form.data("options", this.options);
  },
  
  send: function() {
    this.options.beforeSend.call();
    $.ajax({async: true, 
            beforeSend: function(xhr) {xhr.setRequestHeader('Accept', 'text/javascript')}, 
            data: $.param($(this.form).serializeArray()), 
            dataType: 'script', 
            url: this.options.url});
  },
  
  reset: function() {
    this.options.beforeSend.call();
    $.ajax({async: true, 
            beforeSend: function(xhr) {xhr.setRequestHeader('Accept', 'text/javascript')}, 
            dataType: 'script', 
            url: this.options.url});
  },
  
  addRule: function(ruleName, label, type, values) {
    if(this.types.indexOf(type) != -1) {
      if(typeof(this.rules[ruleName]) != "undefined") {
        throw "Rule for " + ruleName + " already exist";
      }
      
      if(type == 'enum' && typeof(values) != 'object') {
        throw "Enum rule type requires a hash of values as third param";
      }
      
      this.rules[ruleName] = {name: ruleName, label: label, type: type, values: values};
      
      this.form.data("rules", this.rules);
    } else throw "No such rule type";
  },

  // actions

  addRuleLine: function() {
    for (var i in this.rules){
      var rule = this.rules[i];
      break;
    }
    
    var rules = []
    for(var i in this.rules) {
      rules[i] = this.rules[i].label;
    }
    
    var order = this.form.children().length;
        
    var htmlCode = '<p>';
    htmlCode += this.drawSelect("filter[][attr]", rules, "filterWidget(this).updateRuleLine(this)");
    htmlCode += '<span>';
    htmlCode += this.ruleLine(rule);
    htmlCode += '</span>';
    htmlCode += '<a href="#" class="filter_widget_minus" onclick="filterWidget(this).removeRuleLine(this); return false;">-</a>';
    htmlCode += '<a href="#" class="filter_widget_plus" onclick="filterWidget(this).addRuleLine(); return false;">+</a>';
    htmlCode += '</p>';
    
    this.form.children(".filter_widget_submit").before(htmlCode);
    $("input.autocomplete",this.form).each(function() {
        $(this).autocomplete(rule.values);
    });
    return false;
  },

  removeRuleLine: function(elem) {
    if(this.form.children("p").length > 2) {
      $(elem.parentNode).remove();
    }
    
    return false;
  },

  updateRuleLine: function(select) {
    rule = this.rules[select.value];
    $(select.parentNode).children("span").html(this.ruleLine(rule));
    $("input.autocomplete",this.form).each(function() {
        $(this).autocomplete(rule.values);
    });
  },

  // rule html generators
  
  ruleLine: function(rule) {
    if(rule.type == "enum")
      var htmlCode = this.enumRule(rule.name, rule.values);
    else
      var htmlCode = this[rule.type+"Rule"].call(this, rule.name);
    
    return htmlCode;
  },
  
  booleanRule: function(name) {
    var html = '<input type="hidden" name="filter[][op]" value="e" />'
    html += '<input type="radio" name="filter[][value]" value="true" checked="checked"/>' + this.options.strings.val_true 
    html += '<input type="radio" name="filter[][value]" value="false"/>' + this.options.strings.val_false
    return html;
  },

  stringRule: function(name) {
    var html = '<input type="hidden" name="filter[][op]" value="e" />'
    html += '<input type="text" name="filter[][value]" />' 
    return html;
  },

  numericRule: function(name) {
    operators = {e: "=", lt: "<", gt: ">", ltoe: "<=", gtoe: ">=", ne: "!="};
    var html = this.drawSelect("filter[][op]", operators);
    html += '<input type="text" name="filter[][value]" />';
    return html;
  },

  enumRule: function(name, values) {
    var html = '<input type="hidden" name="filter[][op]" value="e" />'
    html += this.drawSelect("filter[][value]", values);
    return html;  
  },

  autocompleteRule: function(name)  {
    var html = '<input type="hidden" name="filter[][op]" value="e" />'
    html += '<input class="autocomplete" type="text" name="filter[][value]" />'
    this.autocomplete = true;
    return html;
  },
  
  // form generators (= helpers)
  
  drawSelect: function(name, options, onchangeCode) {
    select = '<select name="'+ name +'"'+ (typeof(onchangeCode) == "undefined" ? "" : 'onchange="'+onchangeCode+'"') +'>';
    for(var i in options) {
      select += '<option value="'+i+'">'+options[i]+'</option>';
    }
    return select + '</select>';
  }
}

// if jQuery does it, we can do it as well
filterWidget.prototype.init.prototype = filterWidget.prototype;
