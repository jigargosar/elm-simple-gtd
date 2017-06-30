port module DomPorts exposing (..)

import Return


type alias DomSelector =
    String


port focusInput : DomSelector -> Cmd msg


port focusSelector : DomSelector -> Cmd msg


port focusSelectorIfNoFocus : DomSelector -> Cmd msg


autoFocusInputCmd =
    focusInputCmd ".auto-focus"


focusInputCmd =
    focusInput >> Return.command


focusSelectorIfNoFocusCmd =
    focusSelectorIfNoFocus >> Return.command


port positionPopupMenu : DomSelector -> Cmd msg
