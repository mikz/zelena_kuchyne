/*
 * Translated default messages for the jQuery validation plugin.
 * Language: CS
 */
jQuery.extend(jQuery.validator.messages, {
	nameOrCompany: "Musíte vyplnit jméno a příjmení nebo název společnosti a IČ.",
	phone_number: "Zadejte platné tel. č. ",
	psc: "Zadejte platné PSČ.",
	person_name: "Zadejte jméno.",
	email: "Zadejte platný email.",
	required: "Tento údaj je povinný.",
	remote: "Prosím, opravte tento údaj.",
	email: "Prosím, zadejte platný e-mail.",
	url: "Prosím, zadejte platné URL.",
	date: "Prosím, zadejte platné datum.",
	dateISO: "Prosím, zadejte platné datum (ISO).",
	number: "Prosím, zadejte číslo.",
	digits: "Prosím, zadávejte pouze číslice.",
	creditcard: "Prosím, zadejte číslo kreditní karty.",
	equalTo: "Prosím, zadejte znovu stejnou hodnotu.",
	accept: "Prosím, zadejte soubor se správnou příponou.",
	maxlength: jQuery.format("Prosím, zadejte nejvíce {0} znaků."),
	minlength: jQuery.format("Prosím, zadejte nejméně {0} znaků."),
	rangelength: jQuery.format("Prosím, zadejte od {0} do {1} znaků."),
	range: jQuery.format("Prosím, zadejte hodnotu od {0} do {1}."),
	max: jQuery.format("Prosím, zadejte hodnotu menší nebo rovnu {0}."),
	min: jQuery.format("Prosím, zadejte hodnotu větší nebo rovnu {0}."),
	login: "Špatný formát přihlašovacího jména."
});



if($.datepicker) {
  /* Czech initialisation for the jQuery UI date picker plugin. */
  /* Written by Tomas Muller (tomas@tomas-muller.net). */
  jQuery(function($){
  	$.datepicker.regional['cs'] = {
  		closeText: 'Zavřít',
  		prevText: '&#x3c;Dříve',
  		nextText: 'Později&#x3e;',
  		currentText: 'Nyní',
  		monthNames: ['leden','únor','březen','duben','květen','červen',
          'červenec','srpen','září','říjen','listopad','prosinec'],
  		monthNamesShort: ['led','úno','bře','dub','kvě','čer',
  		'čvc','srp','zář','říj','lis','pro'],
  		dayNames: ['neděle', 'pondělí', 'úterý', 'středa', 'čtvrtek', 'pátek', 'sobota'],
  		dayNamesShort: ['ne', 'po', 'út', 'st', 'čt', 'pá', 'so'],
  		dayNamesMin: ['ne','po','út','st','čt','pá','so'],
  		weekHeader: 'Týd',
  		dateFormat: 'yy-mm-dd',
  		firstDay: 1,
  		isRTL: false,
  		showMonthAfterYear: false,
  		yearSuffix: ''};
  	$.datepicker.setDefaults($.datepicker.regional['cs']);
  });
}