module Overlays.LaunchBar exposing (..)

import LaunchBar.Models exposing (LaunchBarForm, SearchItem)


type LaunchBarMsg
    = NOOP
    | OnLBEnter SearchItem
    | OnLBInputChanged LaunchBarForm String
    | Open
    | OnCancel
