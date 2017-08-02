module Models.HasStores exposing (..)

import GroupDoc exposing (..)
import Page exposing (Page)
import TodoDoc exposing (..)


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
