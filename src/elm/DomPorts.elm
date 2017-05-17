port module DomPorts exposing (..)

import Dom
import Return
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


type alias DomSelector =
    String


port focusPaperInput : DomSelector -> Cmd msg


port focusSelector : DomSelector -> Cmd msg


port focusSelectorIfNoFocus : DomSelector -> Cmd msg


autoFocusPaperInputCmd =
    focusPaperInputCmd ".auto-focus"


focusPaperInputCmd =
    focusPaperInput >> Return.command


focusSelectorIfNoFocusCmd =
    focusSelectorIfNoFocus >> Return.command


port positionDropdown : ( Dom.Id, Dom.Id ) -> Cmd msg
