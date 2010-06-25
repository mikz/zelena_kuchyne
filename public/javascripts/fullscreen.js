function set_fullscreen_state(state) {
  var saved_states = eval("("+jQuery.cookie('zelenakuchyne_fullscreen_states')+")") || {};
  var arr = document.location.pathname.split("/");
  var url = {};
  if(arr[1]) {
    if(!arr[2]) {
      arr[2] = "index";
    }
    if(typeof url[arr[1]] == "undefined") {
        url[arr[1]] = {};
    }
    url[arr[1]][arr[2]] = state;
  }
  jQuery.extend(true, saved_states,url);
  jQuery.cookie('zelenakuchyne_fullscreen_states', JSON.stringify(saved_states) , { path: '/', expires: 10 });
}
function get_fullscreen_state() {
  var saved_states = eval("("+jQuery.cookie('zelenakuchyne_fullscreen_states')+")");
  var arr = document.location.pathname.split("/");
  if(arr[1]) {
    if(saved_states && saved_states[arr[1]]) {
      return saved_states[arr[1]][arr[2]||"index"];
    }
  }
  return false;
}

$(function(){
  var init = function(){
    if(get_fullscreen_state()){
      $("#text").addClass("fullscreen");
    }
  }
  $("#text").prepend('<div class="fullscreen_button"></div>');
  $(".fullscreen_button").click(
    function(){
      $("#text").toggleClass("fullscreen");
      var fullscreen = $("#text").hasClass("fullscreen");
      set_fullscreen_state(fullscreen);
  });
  
  if(typeof JSON == "undefined") {
    jQuery.getScript("/javascripts/json2.js", init());
  }
  else {
    init();
  }
});