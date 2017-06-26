import {run} from 'runjs'
import * as _ from "ramda"
import LineDriver from "line-driver"

export default function () {
    LineDriver.read( {
        in : 'main-warn.txt',
        line : function( props, parser ){
            console.log( parser.line );
        }
    } );
}
