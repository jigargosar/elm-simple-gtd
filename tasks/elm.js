import {run} from 'runjs'
import * as _ from "ramda"
import LineDriver from "line-driver"

function fixWarningsFrom(warnFilePath) {
    LineDriver.read({
        sync: true,
        in: warnFilePath,
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
    })
}
export const removeUnusedImports = function() {
    run("rimraf ./elm-stuff/build-artifacts/0.18.0/jigargosar")
    // run(`bash -c "shopt -s globstar && rm -fv elm-stuff/build-artifacts/0.18.0/jigargosar/**/L-*.*"`)

    const warnFilePath = '/tmp/main-warn.txt'

    run(`elm-make --warn src/elm/L/Main.elm --output /dev/null 2> ${warnFilePath}`)
    fixWarningsFrom(warnFilePath)


    run(`elm-make --warn src/elm/Main.elm --output /dev/null 2> ${warnFilePath}`)
    fixWarningsFrom(warnFilePath)

    run("elm-format --yes src/elm/**.elm")
}

export const parseWPD = function() {
    LineDriver.read({
        in: 'wp-dev-server.log',
        line: function (props, parser) {
            const line = parser.line
            // console.log(parser.line);

            if (props.fileName) {
                const lineNumRegexp = /^([0-9]+)\|/
                const match = lineNumRegexp.exec(line)
                if (match) {
                    // run("line-replace " + props.fileName + ":" + match[1] + " > /dev/null")
                    props.fileName = null
                }

            } else {
                // const unusedImportRegexp = /^-- PORT ERROR -+ ([./a-zA-Z0-9]+)$/
                const unusedImportRegexp = /^-- PORT ERROR -+ (.+)$/
                const match = unusedImportRegexp.exec(line)
                if (match) {
                    props.fileName = match[1]
                    console.error(props.fileName+":1-3 -- Error: Foo");
                    // console.log("fileName", props.fileName)
                }
            }
        }
    })
    // run("tail -F wp-dev-server.log")
}
