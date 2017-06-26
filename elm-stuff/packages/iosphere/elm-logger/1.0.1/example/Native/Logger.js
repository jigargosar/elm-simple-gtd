// Make sure to change the function name to match your project.
var  _iosphere$elm_logger$Native_Logger = function() {


/* The implementation is similar to
	https://github.com/elm-lang/core/blob/5.0.0/src/Native/Debug.js

	The main difference is that it adds color coding to the message along with
	a label showing the log level.
*/
function log(level, color, tag, value)
{
	var stringValue = _elm_lang$core$Native_Utils.toString(value);
	var process = process || {};
	if (process.stdout)
	{
		process.stdout.write(tag + ": " + stringValue);
	}
	else
	{
		var colorPrefix = "%c";
		var border = "border-radius: 4px; border: 1px solid " + color + ";";
		var textColor = "color: " + color + ";";

		var levelStyle = "padding: 0 7px 0 5px; margin-right: -5px; "
						+ "font-weight: bold;" + textColor + border;
		var tagStyle = "color: white; padding: 0 5px; "
						+ "margin-right: 5px; font-weight: bold; "
						+ "background-color: " + color + ";" + border;
		var msgStyle = "color: " + color;

		var coloredMsg = colorPrefix + stringValue;
		var coloredLevel = colorPrefix + level;
		var coloredTag = colorPrefix + tag +":";

		console.log(coloredLevel + coloredTag+ coloredMsg, levelStyle,tagStyle, msgStyle);
	}
	return value;
}

return {
	log: F4(log)
};

}();
