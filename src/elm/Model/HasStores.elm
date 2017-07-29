module Model.HasStores exposing (..)

import Page exposing (Page)
import Types.GroupDoc exposing (..)
import Types.Todo exposing (..)


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
