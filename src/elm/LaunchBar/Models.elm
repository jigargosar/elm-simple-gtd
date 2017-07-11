module LaunchBar.Models exposing (..)

import GroupDoc.Types exposing (ContextDoc, GroupDoc, ProjectDoc)
import Regex
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import Context
import Fuzzy
import Toolkit.Operators exposing (..)
import Project
import String.Extra


type LBEntity
    = LBContext ContextDoc
    | LBProject ProjectDoc
    | LBProjects
    | LBContexts


type Result
    = Canceled
    | Selected LBEntity


type alias LaunchBar =
    { input : String
    , updatedAt : Time
    , searchResults : List ( LBEntity, Fuzzy.Result )
    , maybeResult : Maybe Result
    }


initialModel : Time -> LaunchBar
initialModel now =
    { input = ""
    , updatedAt = now
    , searchResults = []
    , maybeResult = Nothing
    }


defaultEntity =
    LBContext Context.null
