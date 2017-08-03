port module DomPorts exposing (..)

import Return


type alias DomSelector =
    String


port focusSelector : DomSelector -> Cmd msg


port positionPopupMenu : DomSelector -> Cmd msg
