module LaunchBar.Messages exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import LaunchBar.Models exposing (SearchItem, LaunchBar)
import Time exposing (Time)


type Msg
    = NOOP
    | OnLBEnter SearchItem
    | OnLBInputChanged LaunchBar String
    | Open
    | OnCancel
