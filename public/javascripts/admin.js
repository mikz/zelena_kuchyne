jQuery(function() {
  if(jQuery.cookie('zelenakuchyne_show_admin_menu')) {
    jQuery('#admin_menu_backdrop').css({
      'height': '170px',
      'opacity': '0.9',
      'backgroundColor': '#000',
      'borderBottomWidth': '2px'
    });
    jQuery('#admin_menu').show();
    jQuery('#admin_menu').css({
      'opacity': '1'
    });
    jQuery('#admin_title').css({
      'opacity': '0'
    });
  }
  jQuery('#admin_menu_backdrop').css('visibility', 'visible');
  jQuery('#admin_menu_backdrop').click(
    function() {
      jQuery.cookie('zelenakuchyne_show_admin_menu', 'show', { path: '/', expires: 10 });
      jQuery('#admin_menu_backdrop').animate(
        {
          'height': '170px',
          'opacity': '0.9',
          'backgroundColor': '#000',
          'borderBottomWidth': '2px'
        },
        'slow',
        'swing',
        function() {
          jQuery('#admin_menu').show();
          jQuery('#admin_menu').animate({
            'opacity': '1'
          }, 'slow');
        });
      jQuery('#admin_title').animate({
        'opacity': '0',
        'letterSpacing': '20px',
        'paddingLeft': '200px',
        'fontSize': '24px'
      }, 'slow');
    }
  );

  jQuery('#admin_hide').click(
    function() {
      jQuery.cookie('zelenakuchyne_show_admin_menu', null, { path: '/' });
      jQuery('#admin_menu').animate(
        {
          'opacity': '0'
        },
        'slow',
        'swing',
        function() {
          jQuery('#admin_menu').hide();
          jQuery('#admin_menu_backdrop').animate(
            {
              'opacity': '1',
              'height': '24px',
              'backgroundColor': '#ad1f00',
              'borderBottomWidth': '0'
            },
            'slow',
            'swing',
            function() {
              jQuery('#admin_title').css('paddingLeft', '24px');
              jQuery('#admin_title').css('letterSpacing', '0');
              jQuery('#admin_title').css('fontSize', '12px');
              jQuery('#admin_title').animate({
                'opacity': '1'
              }, 'slow');
            }
          );
        }
      );
    }
  );
  
  $(".to_xls").click(function(){
    if(confirm('Chápu, že export můze trvat i několik minut.')) {
      var disable = function(element){
        $(element).attr('disabled', true);
      }
      setTimeout(disable, 300, this);
    } else {
      return false;
    }
    
  });
});