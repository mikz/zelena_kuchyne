jQuery.fn.extend({
  add_all_items: function(){
    var meal_form;
    form = this;
    this.children("input:hidden").remove();
    jQuery("form:has(input:text.amount_input)").each(function(i){
      item_id = jQuery("input[name='item[item_id]']",this).attr("value");
      amount = jQuery("input.amount_input", this).attr("value");
      if(amount && item_id) {
        form.append('<input type="hidden" name=item[item_ids][] value="'+item_id+'"/>');
        form.append('<input type="hidden" name=item[amounts]['+item_id+'] value="'+amount+'"/>');
      }
    });
  }
});

jQuery(function(){
  form = jQuery("#add_all_items").show().children("form");
  if(!$(".menus").hasClass("disabled")) {
    form.append('<input type="image" src="/images/all_to_basket.gif" value="vše do košíku"/>');
  }
});