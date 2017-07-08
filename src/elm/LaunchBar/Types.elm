module LaunchBar.Types exposing (..)

import GroupDoc.Types exposing (ContextDoc, ProjectDoc)
import Time exposing (Time)


type LBEntity
    = LBContext ContextDoc
    | LBProject ProjectDoc
    | LBProjects
    | LBContexts


type LBMsg
    = OnLBEnter LBEntity
    | OnLBInputChanged LaunchBarForm String
    | OnLBOpen


type alias LaunchBarForm =
    { input : String
    , updatedAt : Time
    }
