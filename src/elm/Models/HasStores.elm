module Models.HasStores exposing (..)

import Data.TodoDoc exposing (..)
import GroupDoc exposing (..)
import Page exposing (Page)


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
