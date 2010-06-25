/*
 * jQuery plugin: fieldSelection - v0.2.0 - last change: 2008-07-03
 * (c) 2006 Alex Brem <alex@0xab.cd> - http://blog.0xab.cd // edited by MikZ
 */

(function() {

	var fieldSelection = {

		getSelection: function() {

			var e = this.jquery ? this[0] : this;

			return (

				/* mozilla / dom 3.0 */
				('selectionStart' in e && function() {
					var l = e.selectionEnd - e.selectionStart;
					return { start: e.selectionStart, end: e.selectionEnd, length: l, text: e.value.substr(e.selectionStart, l) };
				}) ||

				/* exploder */
				(document.selection && function() {

					e.focus();

					var r = document.selection.createRange();
					if (r == null) {
						return { start: 0, end: e.value.length, length: 0 }
					}

					var re = e.createTextRange();
					var rc = re.duplicate();
					re.moveToBookmark(r.getBookmark());
					rc.setEndPoint('EndToStart', re);

					return { start: rc.text.length, end: rc.text.length + r.text.length, length: r.text.length, text: r.text };
				}) ||

				/* browser not supported */
				function() {
					return { start: 0, end: e.value.length, length: 0 };
				}

			)();

		},
                setSelection: function() {
                        var e = this.jquery ? this[0] : this;
                        var selectionStart = arguments[0] || 0;
                        var selectionEnd = arguments[1] || selectionStart;                        
                        return (

				/* mozilla / dom 3.0 */
				('selectionStart' in e && function() {
					e.selectionStart = selectionStart;
                                        e.selectionEnd = selectionEnd;
					return this;
				}) ||

				/* exploder */
				(document.selection && function() {
					var r = document.selection.createRange();
					r.move('character',-e.value.length);
                                        r.moveStart('character',selectionStart);
                                        r.moveEnd('character',selectionEnd-selectionStart);
                                        r.select();
					return this;
				}) ||

				/* browser not supported */
				function() {
					return this;
				}

			)();
                },
		replaceSelection: function() {

			var e = this.jquery ? this[0] : this;
			var text = arguments[0] || '';

			return (

				/* mozilla / dom 3.0 */
				('selectionStart' in e && function() {
					e.value = e.value.substr(0, e.selectionStart) + text + e.value.substr(e.selectionEnd, e.value.length);
					return this;
				}) ||

				/* exploder */
				(document.selection && function() {
					e.focus();
					document.selection.createRange().text = text;
					return this;
				}) ||

				/* browser not supported */
				function() {
					e.value += text;
					return this;
				}

			)();

		}

	};

	jQuery.each(fieldSelection, function(i) { jQuery.fn[i] = this; });

})();
