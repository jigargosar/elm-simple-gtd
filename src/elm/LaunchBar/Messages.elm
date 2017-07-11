module LaunchBar.Messages exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import LaunchBar.Models exposing (LBEntity, LaunchBar)
import Time exposing (Time)


type LBMsg
    = NOOP
    | OnLBEnter LBEntity
    | OnLBInputChanged LaunchBar String
    | OnLBOpen
    | OnCancel
