jQuery.fn.extend({
  initDialyMenu: function() {
    $.each(this, function(){
      var $this = $(this);
      var row_id = this.id;
      var date = $this.find("#"+row_id+"_date");
      
      $this.find("table").each(function(){
        var $this = $(this);
        var sample = $this.find("tr.sample");
        if(!sample.length)
          return;
          
        $this.data("sample", sample.clone());
        sample.remove();
        
        $this.find(".add").click(function(){
          var sample = $this.data("sample").clone().removeClass("sample");
          var tmpid = (new Date()).valueOf();
          sample.find("[name]").each(function(){
            $(this).attr("name", $(this).attr("name").replace(/(?:\[\]|\[ID\])/, "["+tmpid+"]"));
          });
          $this.find("tbody").append(sample);
          return false;
        });
        
      });
      
      $this.find(".destroy").live("click", function(){
        var input = $(this).next();
        var tr = $(this).closest("tr");
        var both = $([tr[0], tr.next()[0]]);
        both.fadeOut(function(){
          both.hide();
          input.val(1);
        });
        return false;
      })
      
      date.change(function(){
        
      });
      console.log(this, row_id);
    });

  }
});