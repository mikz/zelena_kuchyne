ie_goAway = function(eventObject) {
  eventObject.preventDefault();
  jQuery.cookie('zelenakuchyne_show_ie_notice', 'hide', { path: '/', expires: 9999 });
  
  var notice = jQuery('#ie_notice');
  notice.animate({
    opacity: 0,
    height: 0,
    paddingBottom: 0,
    paddingTop: 0
  }, 750, 'swing', function(){
    notice.remove();
  });
}

jQuery(function() {
  jQuery('#ie_go_away').click(ie_goAway);
  if(jQuery.cookie('zelenakuchyne_show_ie_notice') != 'hide') {
    jQuery('#ie_notice').show();
  }
});