module Model.HasStores exposing (..)

import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Page exposing (Page)
import Todo.Types exposing (TodoStore)


type alias HasStores x =
    { x
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias HasViewType x =
    { x
        | viewType : Page
    }
