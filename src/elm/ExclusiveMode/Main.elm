module ExclusiveMode.Main exposing (..)

import DomPorts exposing (autoFocusInputCmd)
import ExclusiveMode
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Return


start exclusiveMode =
    case exclusiveMode of
        ExclusiveMode.NewTodo form ->
            identity
                >> autoFocusInputCmd

        _ ->
            identity
