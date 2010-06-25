window.addEvent("domready", function () {
	//var tp1 = new TimePicker('time_of_delivery', 'time1', 'time1_toggler', {imagesPath:"../images/time_picker"});
	//var tp2 = new TimePicker('time2_picker', 'time2', 'time2_toggler', {format24:true,imagesPath:"../images/time_picker"});
	var tp = new TimePicker('time_picker', 'time_of_delivery', 'time_toggler', {format24:true,imagesPath:"../images/time_picker"});
});