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


type SearchItem
    = SI_Context ContextDoc
    | SI_Project ProjectDoc
    | SI_Projects
    | SI_Contexts


type Result
    = Canceled
    | Selected SearchItem


type alias LaunchBar =
    { input : String
    , updatedAt : Time
    , searchResults : List ( SearchItem, Fuzzy.Result )
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
    SI_Context Context.null


getSearchItemName searchItem =
    case searchItem of
        SI_Project project ->
            Project.getName project

        SI_Context context ->
            Context.getName context

        SI_Projects ->
            "Projects"

        SI_Contexts ->
            "Contexts"
