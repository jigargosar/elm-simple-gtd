module LaunchBar.Messages exposing (..)

import LaunchBar.Models exposing (SearchItem, LaunchBarForm)


type LaunchBarMsg
    = NOOP
    | OnLBEnter SearchItem
    | OnLBInputChanged LaunchBarForm String
    | Open
    | OnCancel
