var lost_items = {
  add_user: function(after_elem) {
    var user_elem = jQuery("input[name='record[user]']");
    var users_elem = jQuery('<input type="text" name="record[users][]" class="{required: true}"/>');
    if(user_elem.length > 0){
      user_elem.replaceWith(users_elem);
    }
    jQuery(after_elem).parent().before(users_elem);
    users_elem.autocomplete("/users/find/?filter%5B%5D%5Battr%5D=groups.system_name&filter%5B%5D%5Bop%5D=e&filter%5B%5D%5Bvalue%5D=deliverymen");
  }
};
