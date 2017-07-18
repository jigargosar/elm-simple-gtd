module CommonMsg exposing (update, createHelper)

import CommonMsg.Types exposing (Msg(..))
import DomPorts exposing (DomSelector)
import Return
import X.Debug


update msg =
    case msg of
        NoOp ->
            Cmd.none |> Return.command

        Focus selector ->
            selector |> DomPorts.focusSelector |> Return.command

        LogString string ->
            let
                _ =
                    X.Debug.log "CM:LogString" string
            in
                update NoOp


type alias Helper msg =
    { noOp : msg
    , focus : DomSelector -> msg
    , logString : String -> msg
    }


createHelper : (Msg -> msg) -> Helper msg
createHelper tagger =
    { noOp = tagger NoOp
    , focus = Focus >> tagger
    , logString = LogString >> tagger
    }
