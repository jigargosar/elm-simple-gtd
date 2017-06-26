import {run} from 'runjs'
import * as _ from "ramda"
import LineDriver from "line-driver"

export default function () {
    run("elm-make --warn src/elm/Main.elm --output /dev/null 2> /tmp/main-warn.txt")
    LineDriver.read({
        in: '/tmp/main-warn.txt',
        line: function (props, parser) {
            const line = parser.line
            // console.log(parser.line);

            if (props.fileName) {
                const lineNumRegexp = /^([0-9]+)\|/
                const match = lineNumRegexp.exec(line)
                if (match) {
                    run("line-replace " + props.fileName + ":" + match[1] + " > /dev/null")
                    props.fileName = null
                }

            } else {
                const unusedImportRegexp = /^-- unused import -* ([./a-zA-Z0-9]+)$/
                const match = unusedImportRegexp.exec(line)
                if (match) {
                    console.log(match[1]);
                    props.fileName = match[1]
                    // console.log("fileName", props.fileName)
                }
            }
        }
    });
}
