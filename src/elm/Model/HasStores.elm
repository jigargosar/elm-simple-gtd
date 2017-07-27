module Model.HasStores exposing (..)

import GroupDoc.Types exposing (ContextStore, ProjectStore)
import Todo.Types exposing (TodoStore)
import ViewType exposing (ViewType)


type alias HasStores x =
    { x
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias HasViewType x =
    { x
        | viewType : ViewType
    }