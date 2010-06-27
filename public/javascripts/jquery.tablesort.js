//made from: http://www.lukedingle.com/javascript/sortable-table-rows-with-jquery-draggable-rows/

(function($){
$.fn.dragrow = function(settings){
var defaults = {
onDrop: function(){}
};

settings = $.extend(defaults,settings);

//IE Doesn’t stop selecting text when mousedown returns false we need to check
// That onselectstart exists and return false if it does — we won’t check if the browser is IE
// As thy may very well change this at some point
var need_select_workaround = typeof $(document).attr("onselectstart") != "undefined";

return this.bind("mousedown.dragrow",function(e){
  var row = this;
// Store the current location Y axis position of the mouse at the time the
// mouse button was pushed down. This will determine which direction to move the table row
lastY = e.pageY;
// store $(this) tr element in a variable to allow faster access in the functions soon to be declared
var tr = $(this);
// This is just for flashiness. It fades the TR element out to an opacity of 0.2 while it is being moved.
tr.fadeTo("fast", 0.2);
// jQuery has a fantastic function called mouseenter() which fires when the mouse enters
// This code fires a function each time the mouse enters over any TR inside the tbody — except $(this) one
$("tr", tr.parent() ).not(tr).bind("mouseenter.dragrow",function(){
// Check mouse coordinates to see whether to pop this before or after
// If e.pageY has decreased, we are moving UP the page and insert tr before $(this) tr where
// $(this) is the tr that is being hovered over. If e.pageY has decreased, we insert after
if (e.pageY > lastY) {
$(this).after(tr);
} else {
$(this).before(tr);
}
// Store the current location of the mouse for next time a mouseenter event triggers
lastY = e.pageY;
});
// Now, bind a function that runs on the very next mouseup event that occurs on the page
// This checks for a mouse up *anywhere*, not just on table rows so that the function runs even
// if the mouse is dragged outside of the table.
$("body").bind("mouseup.dragrow",function(){
//Fade the TR element back to full opacity
tr.fadeTo("fast", 1);
// Remove the mouseenter events from the tbody so that the TR element stops being moved
$("tr", tr.parent()).unbind("mouseenter.dragrow");
// Remove this mouseup function until next time
$("body").unbind("mouseup.dragrow");
// Make text selectable for IE again with
// The workaround for IE based browsers
if(need_select_workaround) $(document).unbind("selectstart");

settings.onDrop.call(row, tr);
});
// This part if important. Preventing the default action and returning false will
// Stop any text in the table from being highlighted (this can cause problems when dragging elements)
e.preventDefault();

// The workaround for IE based browers
if (need_select_workaround) $(document).bind("selectstart", function () { return false; });
return false;
}).css("cursor", "move");
};
})(jQuery);