module LaunchBar.Models exposing (..)

import Context
import Fuzzy
import GroupDoc.Types exposing (ContextDoc, GroupDoc, ProjectDoc)
import Project
import Time exposing (Time)


type SearchItem
    = SI_Context ContextDoc
    | SI_Project ProjectDoc
    | SI_Projects
    | SI_Contexts


type Result
    = Canceled
    | Selected SearchItem


type alias LaunchBarForm =
    { input : String
    , updatedAt : Time
    , searchResults : List ( SearchItem, Fuzzy.Result )
    }


initialModel : Time -> LaunchBarForm
initialModel now =
    { input = ""
    , updatedAt = now
    , searchResults = []
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
