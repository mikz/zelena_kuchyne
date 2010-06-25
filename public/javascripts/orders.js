function init_draggable_orders(){
  jQuery("#orders .order").draggable({
    helper: function(event){
      return $('<div class="drag-orders-item"><table class="order"></table></div>').find('table').append(jQuery(event.target).closest('tr').clone()).end();
    },
  }).droppable({
    over: function(event, ui){
      jQuery(event.target).addClass("highlight");
    },
    out: function(event, ui){
      jQuery(event.target).removeClass("highlight");
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

$(function() {
  jQuery("#deliver_at_date").datepicker();
  init_draggable_orders();
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