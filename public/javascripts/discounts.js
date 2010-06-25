jQuery.validator.addMethod("min_date", function(value,element,param) {
    var min_date = false;
    var value = parse_datestring(value);
    if(param[0] == "#")
      param = jQuery(param).val();
    param = parse_datestring(param);
    if(value>=param)
      min_date = true;
    return this.optional(element) || min_date
},jQuery.format("Minimal value is {0}."));

jQuery.validator.addMethod("max_date", function(value,element,param) {
    var max_date = false;
    var value = parse_datestring(value);
    if(param[0] == "#")
      param = jQuery(param).val();
    param = parse_datestring(param);
    if(value<=param || !param)
      max_date = true;
    return this.optional(element) || max_date
},jQuery.format("Maximal value is {0}."));