function update_basket(e) {
  $(this).before("<input type='hidden' name='update' value='1'/>");
  var form = jQuery(this.form);
  jQuery.ajax({
      async: true,
      beforeSend:function(xhr) {
          xhr.setRequestHeader('Accept', 'text/javascript')
      },
      data: jQuery.param(form.serializeArray()),
      dataType:'script',
      type: form.attr("method") || "POST",
      url: form.attr("action")
  });
  return false;
}

function submit_confirmation(e) {
  var delivery_fee = jQuery("#delivery_fee").html();
  jQuery("#submit_confirmation ul li:first strong").html((delivery_fee)?delivery_fee : "0 Kč");
  jQuery("#submit_confirmation ul li:last strong").html(jQuery("#time_of_delivery").val());
  jQuery("#submit_confirmation").show("slow");
  return false;
}
function before_submit(elem) {
  if (send_form)
   return false;

  return true;
}
var form_onsubmit;
var send_form;
jQuery(function() {
//  console.log(window.location.pathname, window.location.pathname == "/basket")
  if(window.location.pathname == "/basket") {
      jQuery("#order_confirmed").bind("click",function() {
//        console.log("clicked")
      if(this.checked) {
        jQuery("#submit_confirmation p:first").hide();
        jQuery("#submit_confirmation p:last button:first").attr("disabled",false);
      }
      else {
        jQuery("#submit_confirmation p:first").show();
        jQuery("#submit_confirmation p:last button:first").attr("disabled",true);
      }
    }).triggerHandler("click");
    var form = jQuery("form[action$='/basket/submit']");
    
    jQuery(".confirm_yes").click(function(e) {
      form.unbind("submit", submit_confirmation);
      form.append("<input type='hidden' name='validate' value='1'/>");
      send_form = true;
      form.submit();
    });
    jQuery(".confirm_no").click(function(e) {
      jQuery("#submit_confirmation").hide("slow");
      return false;
    });
    form_onsubmit = form.attr("onsubmit");
    
    form.bind('submit', submit_confirmation);
    if(typeof(form_onsubmit) != "undefined") {
      form.get(0).setAttribute("onsubmit","if(before_submit(this)) { return false };"+form_onsubmit);
    }
    jQuery("input[name=update]").bind('click', update_basket);
  }
});