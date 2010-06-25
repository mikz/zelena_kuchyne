var scheduled_items = {
    load: function( date, elem, restaurant, products, always_available) {
      restaurant = restaurant || false;
      products = products || false;
      always_available = always_available || false;
      var options = {date: date, elem: elem, completed: {scheduled: false, products: false, restaurant: false, always_available: false}, products: false, restaurant: false, always_available: false, selected_id: jQuery(elem + " option:selected").val() };
      scheduled_items.loading(options);
      if(restaurant) {
        options.restaurant = true;
        if(typeof scheduled_items.cache["restaurant"] == "undefined") {
          scheduled_items.fetch_restaurant_meals(options, function(options) {scheduled_items.write(options);});
        } else {
          options.completed.restaurant = true;
        }
      }
      if(always_available) {
        options.always_available = true;
        if(typeof scheduled_items.cache["always_available"] == "undefined") {
          scheduled_items.fetch_always_available(options, function(options) {scheduled_items.write(options);});
        } else {
          options.completed.always_available = true;
        }
      }
      if(products) {
        options.products = true;
        if(typeof scheduled_items.cache["products"] == "undefined") {
          scheduled_items.fetch_products(options, function(options) {scheduled_items.write(options);});
        } else {
          options.completed.products = true;
        }
      }
      if(typeof scheduled_items.cache[date] == "undefined") {
        scheduled_items.fetch(options, function(options) {scheduled_items.write(options);});
      }
      else {
        options.completed.scheduled = true;
        scheduled_items.write(options);
      }
    },
    fetch_restaurant_meals: function(options, callback) {
      var url = options.url || "/meals";
      url += "?format=json&filter%5B%5D%5Battr%5D=restaurant_flag&filter%5B%5D%5Bop%5D=e&filter%5B%5D%5Bvalue%5D=true";
      jQuery.ajax({
        async: true,
        dataType: "json",
        url: url,
        success: function(data){
          var meals = scheduled_items.cache["restaurant"] || {};
          jQuery.each(data, function(i,meal){
            meals[meal.item_id] = {amount: null, item_id: meal.item_id, name: meal.name };
          });
          scheduled_items.cache["restaurant"] = meals;
          options.completed.restaurant = true;
          if(typeof callback != "undefined") {
            callback(options);
          }
        }
      });
    },
    fetch_always_available: function(options, callback) {
      var url = options.url || "/meals";
      url += "?format=json&filter%5B%5D%5Battr%5D=always_available&filter%5B%5D%5Bop%5D=e&filter%5B%5D%5Bvalue%5D=true";
      jQuery.ajax({
        async: true,
        dataType: "json",
        url: url,
        success: function(data){
          var meals = scheduled_items.cache["restaurant"] || {};
          jQuery.each(data, function(i,meal){
            meals[meal.item_id] = {amount: null, item_id: meal.item_id, name: meal.name };
          });
          scheduled_items.cache["always_available"] = meals;
          options.completed.always_available = true;
          if(typeof callback != "undefined") {
            callback(options);
          }
        }
      });
    },
    fetch: function(options, callback) {
      var url = options.url || "/schedule";
      url += "?id="+options.date+"&format=json";
      jQuery.ajax({
        async: true,
        dataType: "json",
        url: url,
        success: function(data){
          var items = { "menus": {}, "meals": {}, "bundles": {} };
          jQuery.each(data, function(i,item){
            jQuery.each(item.scheduled_meals, function(i, meal){
              items["meals"][meal.meal.item_id] = {amount: meal.amount, item_id: meal.meal.item_id, name: meal.meal.name };
            });
            jQuery.each(item.scheduled_menus, function(i, menu){
              items["menus"][menu.menu.item_id] = { amount: menu.amount, item_id: menu.menu.item_id, name: menu.menu.name  };
              jQuery.each(menu.menu.meals, function(i, meal){
                items["meals"][meal.item_id] = { amount: menu.amount, item_id: meal.item_id, name: meal.name };
              });
            });
            jQuery.each(item.scheduled_bundles, function(i, bundle){
              items["bundles"][bundle.bundle.item_id] = { amount: null, item_id: bundle.bundle.item_id, name: bundle.bundle.name };
            });
          });
          scheduled_items.cache[options.date] = items;
          options.completed.scheduled = true;
          if(typeof callback != "undefined") {
            callback(options);
          }
        }
      });
    },
    fetch_products: function(options, callback) {
      var url = "/products";
      url += "?format=json";
      jQuery.ajax({
        async: true,
        dataType: "json",
        url: url,
        success: function(data){
          var items = {};
          jQuery.each(data, function(i,item){
            items[item.item_id] = {amount: item.amount, item_id: item.item_id, name: item.name };
          });
          scheduled_items.cache["products"] = items;
          options.completed.products = true;
          if(typeof callback != "undefined") {
            callback(options);
          }
        }
      });
    },
    loading: function(options) {
      jQuery(options.elem).html("<option>...načítám...</option>");
    },
    write: function(options){
      completed = options.completed;
      if( !((options.restaurant == completed.restaurant ) && (completed.scheduled) && (options.products == completed.products)) ){
        return;
      }
      date = options.date;
      elem = options.elem;
      selected_id = options.selected_id;
      var original_options = options;
      var options = "<option/>\n";
      if(original_options.restaurant) {
        options += '<optgroup label="restaurace">';
        jQuery.each(scheduled_items.cache["restaurant"] || [], function(i, meal) {
          options += "\n\t<option value='"+meal.item_id+"'>"+meal.name+"</option>";
        });
        options += "\n</optgroup>";
      }
      options += '<optgroup label="jídla">';
      jQuery.each(scheduled_items.cache[date]["meals"] || [], function(i, meal) {
        options += "\n\t<option value='"+meal.item_id+"'>"+meal.name+"</option>";
      });      
      options += "\n</optgroup>";
      options += '<optgroup label="menu">';
      jQuery.each(scheduled_items.cache[date]["menus"] || [], function(i, menu) {
        options += "\n\t<option value='"+menu.item_id+"'>"+menu.name+"</option>";
      });
      options += "\n</optgroup>";
      
      if(original_options.always_available) {
        options += '<optgroup label="stálá nabídka">';
        jQuery.each(scheduled_items.cache["always_available"] || [], function(i, meal) {
          options += "\n\t<option value='"+meal.item_id+"'>"+meal.name+"</option>";
        });
        options += "\n</optgroup>";
      }
      options += '<optgroup label="sestavy">'
      jQuery.each(scheduled_items.cache[date]["bundles"] || [], function(i, bundle) {
        options += "\n\t<option value='"+bundle.item_id+"'>"+bundle.name+"</option>";
      });
      options += "\n</optgroup>";
      if(original_options.products) {
        options += '<optgroup label="zboží">';
        jQuery.each(scheduled_items.cache["products"] || [], function(i, product) {
          options += "\n\t<option value='"+product.item_id+"'>"+product.name+"</option>";
        });
        options += "\n</optgroup>";
      }
      jQuery(elem).html(options);
      if(selected_id) {
        jQuery(elem + " option[value="+selected_id+"]").attr("selected","selected");
      }
    },
    cache: {}
 };
