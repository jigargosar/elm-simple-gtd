module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import Entity.ListView
import Html.Attributes exposing (class)
import Html.Keyed
import List.Extra as List
import Maybe.Extra as Maybe
import Models.EntityTree
import RouteUrl.Builder
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type alias Model =
    { path : List String
    , title : String
    , color : Color
    }


initialModel : List String -> Maybe Model
initialModel path =
    case path of
        "done" :: [] ->
            Just
                { path = [ "done" ]
                , title = "Done"
                , color = AppColors.sgtdBlue
                }

        _ ->
            Nothing


view config appVM model =
    let
        entityTree =
            Models.EntityTree.doneTree model
    in
    Html.Keyed.node "div"
        [ class "entity-list focusable-list"
        ]
        (Entity.ListView.keyedViewList config appVM entityTree)
