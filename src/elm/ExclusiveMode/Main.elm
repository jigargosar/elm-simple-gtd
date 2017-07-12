module ExclusiveMode.Main exposing (..)

import DomPorts exposing (autoFocusInputRCmd)
import ExclusiveMode.Types exposing (..)
import Model.Internal exposing (setExclusiveMode)
import Return exposing (map)
import Todo.Form


start exclusiveMode =
    case exclusiveMode of
        XMNewTodo form ->
            Return.map (setExclusiveMode exclusiveMode)
                >> autoFocusInputRCmd

        _ ->
            identity
