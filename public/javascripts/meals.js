function add_row(what, where, errmsg) {
  id = jQuery("input",jQuery(what));
  if( jQuery("#"+id[0].id).length > 0) {
    alert(errmsg);
  } else {
    where.prepend(row);
  }
  return false;
}

var meals = {
  add: {
    ingredient: function(id,errmsg) {
      table = jQuery('#' +id+ '_recipes');
      select = jQuery('#' +id+ '_ingredients');
      option = select[0].options[select[0].selectedIndex];
      row = '<tr><td><label for="' + id + '_recipe_'+ option.value +'">' + option.text + ': </label></td><td><input type="text" onkeyup="decimal_dot_conversion(this)" id="' + id + '_recipe_'+ option.value +'" name="new_recipe[' + option.value + ']" value="1" /></td></tr>';
      return add_row(row,table,errmsg);
    },
    spice: function(id,errmsg) {
      table = jQuery('#' + id + '_used_spices');
      select = jQuery('#' + id + '_spices');
      option = select[0].options[select[0].selectedIndex];
      row = '<tr><td><label for="' + id + '_used_spice_' + option.value + '">' + option.text + '</label></td><td><input type="hidden" id="' + id + '_used_spice_' + option.value +'" name="used_spice_ids[]" value="'+option.value+'" /></td></tr>';
      return add_row(row, table, errmsg);
    },
    supply: function(id,errmsg) {
      table = jQuery('#' + id + '_supply_recipes');
      select = jQuery('#' + id + '_supplies');
      option = select[0].options[select[0].selectedIndex];
      row = '<tr><td><label for="' + id + '_recipe_'+ option.value +'">' + option.text + ': </label></td><td><input type="text" onkeyup="decimal_dot_conversion(this)" id="' + id + '_recipe_'+ option.value +'" name="new_recipe[' + option.value + ']" value="1" /></td></tr>';
      return add_row(row, table, errmsg);
    }
  }
}