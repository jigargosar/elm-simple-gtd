module LaunchBar.Messages exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import LaunchBar.Models exposing (LBEntity, LaunchBar)
import Time exposing (Time)


type LBMsg
    = OnLBEnter LBEntity
    | OnLBInputChanged LaunchBar String
    | OnLBOpen
    | OnCancel
