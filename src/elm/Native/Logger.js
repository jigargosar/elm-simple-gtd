const _jigargosar$elm_simple_gtd$Native_Logger = function () {

    function log(level, color, tag, value) {
        const stringValue = _elm_lang$core$Native_Utils.toString(value)
        const process = process || {}
        if (process.stdout) {
            process.stdout.write(tag + ": " + stringValue)
        }
        else {
            const colorPrefix = "%c"
            const border = "border-radius: 4px; border: 1px solid " + color + ";"
            const textColor = "color: " + color + ";"

            const levelStyle = "padding: 0 7px 0 5px; margin-right: -5px; "
                               + "font-weight: bold;" + textColor + border
            const tagStyle = "color: white; padding: 0 5px; "
                             + "margin-right: 5px; font-weight: bold; "
                             + "background-color: " + color + ";" + border
            const msgStyle = "color: " + color

            const coloredMsg = colorPrefix + stringValue
            const coloredLevel = colorPrefix + level
            const coloredTag = colorPrefix + tag + ":"

            console.log(coloredLevel + coloredTag + coloredMsg, levelStyle, tagStyle, msgStyle)
        }
        return value
    }

    return {
        log: F4(log)
    }

}()
