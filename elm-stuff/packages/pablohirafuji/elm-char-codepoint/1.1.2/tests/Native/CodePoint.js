
var _pablohirafuji$elm_char_codepoint$Native_CodePoint = function() {

return {
	toString: function(l) { return String.fromCodePoint.apply( null, _elm_lang$core$Native_List.toArray(l)); },
	toChar: function(l) { return _elm_lang$core$Native_Utils.chr(String.fromCodePoint.apply( null, _elm_lang$core$Native_List.toArray(l))); },
	fromChar: function(c) { return c.codePointAt(0) },
};

}();