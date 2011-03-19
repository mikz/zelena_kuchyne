
jQuery(function() {
  $("#notice").addClass("js");
  
  init_FCKeditor();
  init_jquery_tabs();
  init_externalLinks();
  init_locks();
});

window.onload = function() {
  init_notice();
  init();
}

function init() {
  init_ajax_message();
}
function init_ajax_message() {
  if($("#ajax_message").length == 0)
    $(document.body).append('<div id="ajax_message"></div>');
}
function init_locks(){
  $(":input.lock").click(function(){
    var input = $(this);
    var form = input.closest("form");
    form.bind("submit.lock", function(){
      var disable = function(element){
        element.attr('disabled', true);
      }
      setTimeout(disable, 100, input);
      
      form.unbind("submit.lock");
    });
    
  });
}
function ajax_message(text) {
  var ok_button = '<p><button onclick=\'close_ajax_message();\'>Ok</button></p>';
  center($("#ajax_message").html(text + ok_button).show());
}
function close_ajax_message() {
  $("#ajax_message").hide();
}
function center(element) {
  element.css("left",(window.innerWidth - element.width())/2 + window.scrollX);
  element.css("top",(window.innerHeight - element.height())/2 + window.scrollY);
}
function init_notice() {
  $("#notice").addClass("js");
  setTimeout('show_notice();', 100);
}

function init_externalLinks() {
  jQuery("a[rel=external]").externalLinks();
}
function print_and_close() {
  jQuery(function() {
    window.print();
    window.close();
  });
}
function hide_notice() {
  var e = jQuery('#notice');
  e.animate(
    {
      'opacity': '0'
    },
    'slow',
    'swing',
    function() {
      e.css({
        'visibility': 'hidden'
      })
    }
  );
}

function show_notice() {
  var e = jQuery('#notice');
  jQuery('#notice').css({
    'visibility': 'visible',
    'opacity': '0',
    'borderWidth': '4px'
  });
  jQuery('#notice a.close').css({
    'visibility': 'visible',
    'opacity': '0'
  });
  jQuery('#notice').animate(
    {
      'opacity': '1',
      'marginLeft': ((947 / 2) - (e.width() / 2)) + 'px'
    },
    'slow',
    'swing',
    function() {
      jQuery('#notice').highlight({}, function() {
        jQuery('#notice a.close').animate(
          {
            'paddingRight': '12px'
          },
          'slow',
          'swing'
        );
        jQuery('#notice').animate(
          {
            'marginLeft': '0',
            'paddingTop': '3px',
            'paddingBottom': '3px',
            'width': '560px',
            'fontSize': '12px',
            'borderBottomWidth': '1px',
            'borderLeftWidth': '0',
            'borderRightWidth': '0',
            'borderTopWidth': '0'
          },
          'slow',
          'swing',
          function() {
            jQuery('#notice').highlight({}, function() {
              jQuery('#notice a.close').animate(
                {
                  'opacity': '1'
                },
                'slow',
                'swing'
              )
            });
          }
        );
        /*jQuery('#notice').animate(
          {
            'marginLeft': '600px',
            'opacity': '0'
          },
          'slow',
          'swing',
          function() {
            jQuery('#notice').css('visibility', 'hidden');
          }
        )*/
      });
    }
  );
}

function init_jquery_tabs()
{
  jQuery('.tabs').tabs();
}
function init_FCKeditor() {
  jQuery('textarea[class!="noFCKeditor"]').initFCKeditor({Width: "555px"});
}
function decimal_dot_conversion(input) {
  input.value = input.value.replace(/(\.+|,+)/g,".");
}
function parse_datestring(input) {
  var date = new Date();
  var time_arr = [[0,0,0],[0,0,0]]
  if(input)
    input = input.split(" ");
  else
    return null;

  for(var i=0;i<input.length;i++) {
    switch(i) {
      case 0:
        separator = "-";
        break;
      case 1:
        separator = ":";
        break;
    }
    var tmp = input[i].split(separator);
    for(var j=0;j<tmp.length;j++) {
      time_arr[i][j] = parseInt(tmp[j]);
    }
  }
  date.setFullYear(time_arr[0][0]);
  date.setMonth(--time_arr[0][1]);
  date.setDate(time_arr[0][2]);
  date.setHours(time_arr[1][0]);
  date.setMinutes(time_arr[1][1]);
  date.setSeconds(time_arr[1][2]);
  return date;
}
jQuery.fn.extend({
  externalLinks: function() {
    this.attr("target","_blank");
  },
  update_textareas: function() {
    $('textarea[class!="noFCKeditor"]',this).updateFCKeditor();
  },
  initValidation: function() {
    this.each(function(i){
      jQuery(this).removeAttr("onsubmit");
      var onsubmit = jQuery(this).data("onsubmit");
      if(!onsubmit) {
        onsubmit = "true;";
      }
      jQuery(this).data("onsubmit", onsubmit);

      jQuery(this).validate({
        submitHandler: function(form) {
          $(form).update_textareas();
          if(!eval(jQuery(form).data("onsubmit"))) {
            return false;
          }
          jQuery.ajax({
            async:true,
            beforeSend:function(xhr) {
                xhr.setRequestHeader('Accept', 'text/javascript')
            },
            data: jQuery.param(jQuery(form).serializeArray()),
            dataType:'script',
            type: jQuery(form).attr("method") || "GET",
            url: jQuery(form).attr("action")
          });
        },
        debug: false,
        highlightParent: true,
        errorClass: "formError",
        parentClassRequired: true
      });
    });
  },
  activate: function(speed) {
      if(jQuery("#activate_"+this.attr("id")+":checked").length == 0) {
        this.hide(speed);
      }
      else if(jQuery("#activate_"+this.attr("id")+":checked").length > 0) {
        this.show(speed);
      }
  },
  setValidationRule: function(rule) {
      this.each(function(i) {
          jQuery.data(this,"rules",rule);
      });
  },
  validateElement: function() {
      var form = this.get(0).form;
      var validator = jQuery.data(form, "validator");
      validator.element(this);
  },
  regenerateLinks: function() {
    this.each(function(i) {
      $(this).click(function() {
        jQuery.ajax({
          async:true,
          beforeSend:function(xhr) {
            xhr.setRequestHeader('Accept', 'text/javascript')
          },
          dataType:'script', url: this.href.replace('&amp;', '&')
        });
        return false;
      });
    });
  },
  cleanupFCKeditor: function(deep) {
    if(typeof FCKeditorAPI == "undefined")
     return;
    var removePanel = function(panel) {
      if(panel && panel._IFrame) {
        $(panel._IFrame).remove();
      }
    }
    $.each($("textarea",this), function() {
      if(this.editorInstance && deep) {
        if ( this.editorInstance.Commands) {
          $.each(this.editorInstance.Commands.LoadedCommands, function() {
            removePanel(this._Panel);
          });
        }
        if(this.editorInstance.ToolbarSet && this.editorInstance.ToolbarSet.ToolbarItems) {
          $.each(this.editorInstance.ToolbarSet.ToolbarItems.LoadedItems, function() {
            if(this._Combo) {
              removePanel(this._Combo._Panel);
            }
          });
        }
        if(this.editorInstance.ContextMenu &&  this.editorInstance.ContextMenu._InnerContextMenu) {
          removePanel(this.editorInstance.ContextMenu._InnerContextMenu._Panel);
        }
      }
      delete FCKeditorAPI.Instances[ this.id ];
    });
  },
  updateFCKeditor: function() {
    this.each(function() {
      if(this.editorInstance) {
        this.editorInstance.UpdateLinkedField();
      }
    });
  },
  initFCKeditor: function(options) {
    var settings = jQuery.extend({
        BasePath: "/javascripts/fckeditor/"
    }, options);
    window.FCKeditor_OnComplete = function FCKeditor_OnComplete( editorInstance ) {
      editorInstance.LinkedField.editorInstance = editorInstance;
    }
    var init_editor = function(element) {
      if(element.id && typeof FCKeditor != "undefined") {
        var editor = new FCKeditor(element.id);
        jQuery.extend(true, editor, settings);
        if(element.tagName.toLowerCase() == "textarea") {
          editor.ReplaceTextarea();
        }
        element.editor = editor;
      }
    }
    this.each(function() {
      if(!jQuery.data(this,"FCKeditor")) {
        init_editor(this);
      }
    });
  },
  formatError: function(given) {
      var JSON;
      var errors;
      var list;
      var in_array = function(array, obj) {
        for(var i=0; i < array.length; i++) {
          if(array[i] == obj) {
            return true;
          }
        }
        return false;
      }
      this.each(function(i) {
          if(given){
            JSON = given;
          } else {
            $(this).data("error",jQuery(this).html());
            try {
              JSON = eval(jQuery(this).html());
            } catch (e) {
              throw "Bad JSON - " + e.toString();
            }
            
          }
          var element, form, done;
          done = [];
          form = $(this).parents("form");
          $(".formError",form).removeClass("formError");
          for(var i = 0; i< JSON.length;i++) {
            var element = form.find(":input[name*='["+JSON[i][0]+"]']");
            if(element.length == 0) {
              element = jQuery(":input#"+JSON[i][0]);
            }
            if(JSON[i][0] == "base") {
              var form = $(this).parents("form");
              var id = form.parents("tr.inline_edit").attr("id");
              var base = form.children("input#"+id+"_base");
              if(base.length < 1) {
                form.prepend("<p><input type='hidden' id='"+id+"_base /></p>");
              }
              element = jQuery("input#"+id+"_base");
            }
            if(element.length > 0) {
              element.parent().addClass("formError").append("<label for='"+element.get(0).id+"' generated='true' class='formError'>"+ JSON[i][1] +"</label>");
              element.addClass("formError");
              element.each(function() {
                done[done.length] = this;
              });
              
            } else {
              element = $("#"+JSON[i][0].replace("=_address", ""));
              if(element.length == 1 && element.is("tr")) {
                element.addClass("formError");
                if( !in_array(done, element.get(0) ) ) {
                  $("[for="+JSON[i][0]+"]").parents("tr[generated]").remove();
                }
                if(JSON[i][1] == "ignore") {
                  JSON[i][1] = 'ignorovat <input type="checkbox" value="1" name="'+$("input",element).attr("name").replace(/\[(\w+)\]$/,"[ignore]")+'"/>';
                }
                element.after('<tr class="formError" generated="true"><td colspan="'+element.children().length+'"><label for="'+JSON[i][0]+'" generated="true" class="formError">'+ JSON[i][1] +'</label></td></tr>');
                done[done.length] = element.get(0);
              }
            }
          }
          jQuery(this).html("");
      });
  }
});

function show_rule(rule) {
  elem = $("#rule_"+rule);
  elem.show();
}
function toggle_rule(rule) {
  elem = $("#rule_"+rule);
  elem.toggle();
}

function init_user_autocompleter(key) {
  if(!$.Autocompleter) { return; }
  var key = key || "login";
  
  $.extend($.Autocompleter.defaults, {
    formatItem: function(row, i, max, term) {
       if(row.first_name && row.family_name) {
         term += " | " +row.first_name + " " + row.family_name;
       }
       if(row.company_name) {
         term += " | " + row.company_name;
       }
       return term;
    },

    dataType: "json",
    parse: function(data) {
      data = eval(data);
      parsed = [];
      for (i in data) {
        parsed[parsed.length] = {
          data: data[i],
          value: data[i][key],
          result: data[i][key]
        }
      }
      return parsed;
    }
  });
}

$(function(){
  init_user_autocompleter();
});