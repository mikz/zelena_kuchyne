function set_parent_id(row_id,val) {
  var color = "rgb(173, 31, 0)";
  var input = jQuery("#"+row_id+ "_parent_id");
  var all = jQuery("#"+row_id+" div ul a");
  var self = jQuery("#"+row_id+"_category_id_"+val+" a");
  if(self.css("color") == color) {
    input.val("");
    all.css("color","");
  }
  else {
    input.val(val);
    all.css("color","");
    self.css("color",color);
  }
}
function choose_category(row_id,val) {
  var color = "rgb(173, 31, 0)";
  var self = jQuery("#"+row_id+"_category_id_"+val+" a");
  var value = jQuery("#"+row_id+"_product_category_ids_"+val);
  if(self.css("color") == color) {
    value.remove();
    self.css("color","");
  }
  else {
    jQuery("#"+ row_id +" input:first").after('<input type="hidden" value="'+val+'" name="record[product_category_ids][]" id="'+row_id+'_product_category_ids_'+val+'"/>');
    self.css("color",color);
  }
}

function check_opened(e) {
  if (!e) var e = window.event;
  opened = jQuery("#records_body .inline_edit");
  if(opened.length > 0) {
    if(confirm("Zavřít otevřené kategorie bez uložení?")) {
      close = jQuery("form>a", opened);
      close.trigger("click");
      return true;
    }
    else {
      e.stopPropagation();
      e.preventDefault();
      return false;
    }
  }
  return true;
}