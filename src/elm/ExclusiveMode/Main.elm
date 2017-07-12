module ExclusiveMode.Main exposing (..)

import DomPorts exposing (autoFocusInputRCmd)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Model.Internal exposing (setEditMode)
import Return


start exclusiveMode =
    case exclusiveMode of
        XMNewTodo form ->
            Return.map (setEditMode exclusiveMode)
                >> autoFocusInputRCmd

        _ ->
            identity
