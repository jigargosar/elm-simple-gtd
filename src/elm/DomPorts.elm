port module DomPorts exposing (..)

import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


type alias DomSelector =
    String


port focusPaperInput : DomSelector -> Cmd msg


port focusSelector : DomSelector -> Cmd msg


autoFocusPaperInputCmd =
    focusPaperInputCmd ".auto-focus"


focusPaperInputCmd =
    focusPaperInput >> Return.command
