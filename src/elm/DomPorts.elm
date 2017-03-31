port module DomPorts exposing (..)

import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


port focusPaperInputByQuerySelector : String -> Cmd msg


focusPaperInputCmd selector =
    focusPaperInputByQuerySelector selector |> Return.command
