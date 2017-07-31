module Pages.EntityList exposing (..)

import AppColors
import Color exposing (Color)
import List.Extra as List
import Maybe.Extra as Maybe
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
