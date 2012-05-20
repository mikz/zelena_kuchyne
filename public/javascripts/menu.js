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
  },
  'switch': function () {
    var links = $(this).find('a');
    var ids = $.map(links, function(item){ return $(item).attr('href') });
    var menus = $(ids.join(','));

    links.click(function handleClick(){
      var link = $(this);
      var positionX = window.scrollX, positionY = window.scrollY;
      menus.filter(':visible').fadeOut();
      $(link.attr('href')).fadeIn(function(){
        window.scrollTo(positionX, positionY);
      });
      links.removeClass('active');
      link.addClass('active');
      return false;
    });

    $(links[0]).triggerHandler('click');
  }
});

jQuery(function(){
  form = jQuery("#add_all_items").show().children("form");
  if(!$(".menus").hasClass("disabled")) {
    form.append('<input type="image" src="/images/all_to_basket.gif" value="vše do košíku"/>');
  }
});
