function init_draggable_orders(selector){ 
  jQuery(selector || "#orders .order").draggable({
    helper: function(event){
      return $('<div class="drag-orders-item"><table class="order"></table></div>').find('table').append(jQuery(event.target).closest('tr').clone()).end();
    },
    appendTo: 'body',
    handle: 'td:first-child'
  }).droppable({
    over: function(event, ui){
      var element = jQuery(event.target);
      element.data("background", element.css("background-color"));
      element.css("background-color", null);
      jQuery(event.target).addClass("highlight");
    },
    out: function(event, ui){
      var element = jQuery(event.target);
      element.removeClass("highlight");
      element.css("background-color", element.data("background"));
    },
    drop: function(event, ui) {
      data = {
        dragged: parseInt(ui.draggable.attr("id").match(/\d+/)[0]),
        dropped: parseInt(event.target.id.match(/\d+/)[0])
      }
      if(confirm("Opravdu chcete spojit objednávky?\nPředměty z objednávky č."+data.dragged+" budou přesunuty do objednávky č."+data.dropped+" a objednávka bude zrušena.\nJiné údaje nebudou změněny.")) {
        $.ajax({
          url: "/orders/merge",
          dataType: "script",
          data: data,
          success: function(data, status, request) {
          },
          error: function(request, status, error) {
          }
        });
      } else {
      }
      jQuery(event.target).removeClass("highlight");
    }
  });
}

function init_address_helpers(selector) {
  var helper;
  if(!window.address_helper) {
    helper = window.address_helper = $("<div class='ui-helper-hidden' id='address_helper'></div>");
    helper.appendTo("body");
    helper.css({position: 'absolute'});
    helper.mouseenter(function(){
      helper.show();
    });
    helper.mouseleave(function(){
      helper.hide();
    })
  } else {
    helper = window.address_helper;
  }
  
  jQuery(selector || "#orders .address").mouseenter(function (){
    var $this = $(this);
    var text = $this.text();
    var addr = text.replace(/[\s\n]+/g, ' ').replace(/^\s\s*/, '').replace(/\s\s*$/, '');

    helper.find("a").remove();
    helper.append(
      $("<a/>").attr('href','http://mapy.cz/?query='+addr).append($("<img>").attr('src', 'http://mapy.cz/favicon.ico')).attr('target', "_blank"),
      $("<a/>").attr('href','http://maps.google.cz/maps?q=' + addr).append($("<img>").attr('src', 'http://maps.google.cz/favicon.ico')).attr('target', "_blank")
    );
    var offset = $this.offset();
    
    helper.css({
      top: offset.top,
      left: offset.left - helper.width(),
      marginTop: ($this.height()-helper.height())/2
    }).show();
    
  }).mouseleave(function(){
    helper.mouseleave();
  });
  

}
$(function() {
  jQuery("#deliver_at_date").datepicker();
  init_draggable_orders();
  init_address_helpers();
})

function update_submit_urls(state_url, calendar_url, filter_url) {
  orders_state_url = state_url.replace(/&amp;/g, '&');
  calendar_widget_url = calendar_url.replace(/&amp;/g, '&');
  filter_url = filter_url.replace(/&amp;/g, '&');
  filterWidget("order-rules").updateOptions({url: filter_url});
}

function list_by_state(state) {
  url = orders_state_url.replace('__state__', state);
  $("#orders").empty().prepend('<p><img src="/images/loading.gif" alt="loading"/></p>');
  $("ul.ui-tabs-nav li").removeClass('ui-tabs-selected');
  $("#order-tab-"+state).addClass('ui-tabs-selected');
  $.ajax({
    type: "GET",
    url: url,
    dataType: "script"
  });
}

function update_active_discounts(order_id) {
    jQuery.getScript("/orders/active_discounts/"+order_id);
}