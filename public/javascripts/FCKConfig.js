FCKConfig.AutoDetectLanguage  = false ;
FCKConfig.DefaultLanguage     =  window.top.lang;


FCKConfig.ToolbarSets["Default"] = [
	['Undo','Redo'], ['Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript'],
	['OrderedList','UnorderedList','-','Outdent','Indent','Blockquote'],
	['JustifyLeft','JustifyCenter','JustifyRight','JustifyFull'],["SelectAll", "RemoveFormat"],
	['Link','Unlink','Anchor'],
	['Image','Table','Rule','SpecialChar','PageBreak'],
	['FontFormat','TextColor'],
	['FitWindow','ShowBlocks', 'Source']		// No comma for the last row.
];


FCKConfig.RemoveFormatTags = 'b,big,code,div,del,dfn,em,font,i,ins,kbd,q,samp,small,span,strike,strong,sub,sup,tt,u,var' ;

FCKConfig.EnterMode = 'p' ;			// p | div | br
FCKConfig.ShiftEnterMode = 'br' ;	// p | div | br

FCKConfig.EditorAreaCSS = '/stylesheets/FCKeditor.css' ;
FCKConfig.BrowserContextMenuOnCtrl = true;
FCKConfig.FontFormats	= 'p;h1;h2' ;

FCKConfig.EnableMoreFontColors = false ;
FCKConfig.FontColors = 'FAFAEF,435f23,AD1F00,638C33,EBBB3C,D7DEBB,455F23,F0F2E0' ;

FCKConfig.ImageUploadURL = '/images/image_upload?fck='+Date.now().toString();

FCKConfig.FlashUpload = false;
FCKConfig.LinkUpload = false;
FCKConfig.LinkBrowser = false;
FCKConfig.FlashBrowser = false;
FCKConfig.ImageBrowser = false;


FCKConfig.ProcessHTMLEntities = false;

