port module DomPorts exposing (..)

import Return


type alias DomSelector =
    String


port focusSelector : DomSelector -> Cmd msg


port focusSelectorIfNoFocus : DomSelector -> Cmd msg


focusSelectorIfNoFocusRCmd =
    focusSelectorIfNoFocus >> Return.command


port positionPopupMenu : DomSelector -> Cmd msg
