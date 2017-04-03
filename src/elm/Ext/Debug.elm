module Ext.Debug exposing (tap, tapLog)


tap : (value -> ignore) -> value -> value
tap tapperFunction value =
    let
        _ =
            tapperFunction value
    in
        value


tapLog  transformerFunction logString   =
    tap (transformerFunction >> Debug.log logString)
