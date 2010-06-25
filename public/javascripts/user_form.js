jQuery.fn.extend({
    updateField: function(field) {
      function update(elem,val) {
        if (elem.data("updatable")) {
          elem.val(val)
        }
      }
      jQuery(field).updatable();
      jQuery(this).bind("keyup", {field: jQuery(field)}, function(e) {
        update(e.data.field,this.value);
      });
    },
    updatable: function() {
      function updatable(elem) {
        var updatable;
        if(elem.value.length == 0) {
          updatable = true;
        }
        else {
          updatable = false;
        }
        jQuery(elem).data("updatable",updatable);
      }
      this.bind("keyup", function(e) {
        updatable(this);
      });
      this.each(function() {
        updatable(this);
      });
    },
    updateNameOrCompany: function() {
        var parent_id = jQuery(this).parent().parent().attr("id");
        var validator = jQuery.data(this.get(0).form, "validator");
        var first_name = jQuery("#"+parent_id+"_first_name");
        var family_name = jQuery("#"+parent_id+"_family_name");
        var company_name = jQuery("#"+parent_id+"_company_name");
        var company_registration_no = jQuery("#"+parent_id+"_company_registration_no");

        switch(this.get(0)) {
            case first_name.get(0):
                if (first_name.val() != "") {
                    family_name.rules("add", {required: true});
                }
                else {
                    family_name.rules("add", {required: false});
                }
                break;
            case family_name.get(0):
                if (family_name.val() != "") {
                    first_name.rules("add", {required: true});
                }
                else {
                    first_name.rules("add", {required: false});
                }
                break;
            case company_name.get(0):
                if (company_name.val() != "") {
                    company_name.rules("add", {required: true});
                    if(company_registration_no.length > 0) {
                      company_registration_no.rules("add", {required: true});
                    }
                }
                else {
                    company_name.rules("add", {required: false});
                    if(company_registration_no.length > 0) {
                      company_registration_no.rules("add", {required: false});
                    }
                }
                break;
        }
        validator.element(first_name);
        validator.element(family_name);
        validator.element(company_name);
        if(company_registration_no.length > 0)
          validator.element(company_registration_no);
    }
  });
    
jQuery.validator.addMethod("password", function(value,element) {
    var form = this.currentForm;
    var validator = jQuery.data(form, "validator");
    var user_password_confirmation =  $("#user_password_confirmation");
    var regex = /^\/([^\/]+)\/?([^\/]+)*\/?([^\/]+)*$/;
    var match = regex.exec(form.attributes.getNamedItem("action").value);
    switch (match[2]) {
        case "create":
            $(element).rules("add",{required: true});
            //user_password_confirmation.rules("add",{required: true});
            break;
        case "update":
            $(element).rules("add",{required: false});
            //user_password_confirmation.rules("add",{required: false});
            break;
    }
    setTimeout('$("#user_password_confirmation").validateElement();',1);
    return true;
},"");

jQuery.validator.addMethod("nameOrCompany", function(value,element) {
    var nameOrCompany = false;
    var parent_id = jQuery(element).parent().parent().attr("id");
    var first_name = jQuery("#"+parent_id+"_first_name");
    var family_name = jQuery("#"+parent_id+"_family_name");
    var company_name = jQuery("#"+parent_id+"_company_name");

    nameOrCompany = ( (first_name.val() != "" && family_name.val() != "" || company_name.val() != "") &&
                     !(first_name.val() == "" && family_name.val() == "" && company_name.val() == "")
                    );

    if(parent_id == "user")
        return nameOrCompany;
    else
        return this.optional(element) || nameOrCompany;
},"Please enter first and family name or company name and company registration number. ");

jQuery.validator.addMethod("psc", function(value,element) {
    return this.optional(element) || /((\d{3}\ {1}\d{2})|(\d{5}))/.test(value);
},"Please enter valid zip code. ");

jQuery.validator.addMethod("person_name", function(value, element) {
    return this.optional(element) || /^([^\+\*\!\\\/\=\@\#\$\~\^\&\{\}\°\[\]\;\<\>\_\(\)]*)$/.test(value);
}, "Please enter valid name. ");

jQuery.validator.addMethod("phone_number", function(value,element) {
    return this.optional(element) || /^(\d){9}$/.test(value);
},"Please enter valid phone number. ");

jQuery.validator.addMethod("login", function(value, element) {
   return this.optional(element) || /^[a-z]+([\._]?[a-z]+)+[0-9]*$/.test(value);
}, "Please enter valid login.");

jQuery.validator.addMethod("zone", $.validator.methods.required, 'Musíte vybrat zónu, kam vaše adresa patří dle <a href="/zony.html" target="_blank">mapy</a>.');

jQuery(function() {
  login = jQuery("#user_login");
  login.bind("keyup", function() {
    if(login.attr("defaultValue") == login.val() && login.val().length > 0) {
      login.rules("remove", "remote");
    }
    else {
      login.rules("add", {remote: "/users/validate_user"});
    }
  });
  
  var delivery_man_color = $('#user_delivery_man_color');
  $('#user_delivery_man_color').ColorPicker({
    onSubmit: function(hsb, hex, rgb) {
      delivery_man_color.val("#"+hex).css("background-color","#"+hex);
    },
    onBeforeShow: function () {
      delivery_man_color.ColorPickerSetColor(this.value);
    },
    onChange: function(hsb,hex,rgb) {
       delivery_man_color.css("background-color","#"+hex);
    },
    onHide: function() {
      delivery_man_color.css("background-color",delivery_man_color.val());
    }
  })
  .bind('keyup', function(){
    $(this).ColorPickerSetColor(this.value);
  });
  
});