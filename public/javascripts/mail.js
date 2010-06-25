function toggle_conversation(link) {
  if($(link).hasClass('open')) {
    $(link).removeClass('open');
    $(link).parent().parent().next().remove();
  } else {
    $(link).addClass('open');
    $.ajax({
      type: "GET",
      url: $(link).attr("href"),
      dataType: "script",
    });
  }
  
  return false;
}