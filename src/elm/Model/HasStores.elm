module Model.HasStores exposing (..)

import Page exposing (Page)
import Todo.Types exposing (TodoStore)
import Types.GroupDoc exposing (..)


type alias HasStores x =
    { x
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias HasPage x =
    { x
        | page : Page
    }
