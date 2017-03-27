port module DomPorts exposing (..)

import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


port documentQuerySelectorAndFocus : String -> Cmd msg


focusFirstAutoFocusElement =
    documentQuerySelectorAndFocus ".auto-focus" |> Return.command
