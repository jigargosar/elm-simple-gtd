port module DomPorts exposing (..)

import Return


type alias DomSelector =
    String


port focusInput : DomSelector -> Cmd msg


port focusSelector : DomSelector -> Cmd msg


port focusSelectorIfNoFocus : DomSelector -> Cmd msg


autoFocusInputRCmd =
    Return.command autoFocusInputCmd


autoFocusInputCmd =
    focusInput ".auto-focus"


focusInputRCmd =
    focusInput >> Return.command


focusSelectorIfNoFocusRCmd =
    focusSelectorIfNoFocus >> Return.command


port positionPopupMenu : DomSelector -> Cmd msg
