module CommonMsg exposing (..)

import DomPorts exposing (DomSelector)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Return


type Msg
    = NoOp
    | Focus DomSelector


update msg =
    case msg of
        NoOp ->
            Cmd.none |> Return.command

        Focus selector ->
            selector |> DomPorts.focusSelector |> Return.command


type alias Helper msg =
    { noOp : msg
    , focus : DomSelector -> msg
    }


createHelper : (Msg -> msg) -> Helper msg
createHelper tagger =
    { noOp = tagger NoOp
    , focus = Focus >> tagger
    }
