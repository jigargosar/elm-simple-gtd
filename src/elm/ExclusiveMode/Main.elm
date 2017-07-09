module ExclusiveMode.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import ExclusiveMode.Types exposing (ExclusiveMode(XMNewTodo))
import Model
import Return


start exclusiveMode =
    case exclusiveMode of
        XMNewTodo form ->
            Return.map (Model.setEditMode exclusiveMode)
                >> autoFocusInputCmd

        _ ->
            identity
