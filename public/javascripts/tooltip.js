function init_tooltip() {
    $(document.body).append('<div id="tooltip"></div>');    
}

jQuery.fn.extend({
  tooltip: function(key){
    var key = key || "name";
      this.each(function() {
          if(jQuery.data(this,"tooltip"))
            return;
          var tooltip;
          var JSON;
          if($("#tooltip").length<1) init_tooltip();
          JSON = eval($(this).next().html());
          tooltip = "<ul>";
          for (var i in JSON) {
              tooltip += "<li>" + JSON[i][key] + "</li>";
          }
          tooltip += "</ul>"
          

          jQuery.data(this,"tooltip",tooltip);
          $(this).hover(
            function(e) {
                var tooltip = jQuery.data(this,"tooltip");
                tooltip = $("#tooltip").addClass("tooltip").html(tooltip.toString());
                var off = 0;
                if(tooltip.height() + e.pageY + 30 > window.innerHeight) {
                  off = tooltip.height() + 60 ;
                }
                $(this).mousemove(function(e){
                  $('#tooltip').css("left", e.pageX).css("top", e.pageY - off);
                });
            },
            function(e){
              $("#tooltip").removeClass("tooltip");
              $(this).unbind("mousemove");
          });
      });
  },
  need_info: function(){
    this.each(function() {
      var tooltip;
      var info = $(this).children(".hidden_info").html();
      if(jQuery.data(this,"tooltip"))
        return;
      $(this).data("tooltip",info);
      $(this).hover(
        function(e) {
            var tooltip = jQuery.data(this,"tooltip");
            tooltip = $("#tooltip").addClass("info_tooltip").html(tooltip.toString());
            $(this).mousemove(function(e){
              $('#tooltip').css("left", e.pageX - tooltip.width()/2 ).css("top", e.pageY - (30 + tooltip.height()));
            });
        },
        function(e){
          $("#tooltip").removeClass("info_tooltip");
          $(this).unbind("mousemove");
      });
      $(this).bind("click", function() {
        $(this).children(".hidden_info").toggleClass("visible_info");
      });
    })
  }
});

$(function() {
        init_tooltip();
        $("a[href^='/menus/show/']").tooltip();
        $("a[href^='/meals/show/']").tooltip();
        $("td.need_info").need_info();
});
 