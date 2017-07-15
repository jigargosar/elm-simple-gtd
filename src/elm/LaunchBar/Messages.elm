module LaunchBar.Messages exposing (..)

import LaunchBar.Models exposing (SearchItem, LaunchBar)


type LaunchBarMsg
    = NOOP
    | OnLBEnter SearchItem
    | OnLBInputChanged LaunchBar String
    | Open
    | OnCancel
