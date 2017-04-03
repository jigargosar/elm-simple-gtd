port module DomPorts exposing (..)

import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Types exposing (DomSelector)


port focusPaperInput : DomSelector -> Cmd msg


autoFocusPaperInputCmd =
    focusPaperInputCmd ".auto-focus"


focusPaperInputCmd =
    focusPaperInput >> Return.command
