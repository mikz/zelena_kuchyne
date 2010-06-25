function compute_difference(event) {
  event.data.diff.val(event.data["real"].val() - event.data["current"].val());
  event.data.diff.trigger("change");
}
function show_difference(event) {
  event.data.removeClass();
  event.data.html($(this).val());
  if(parseFloat($(this).val()) > 0) {
    event.data.addClass("more");
  }
  if(parseFloat($(this).val()) < 0) {
    event.data.addClass("less");
  }
}