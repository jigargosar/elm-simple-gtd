module L.Main exposing (..)

import Html
import L.View
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Return


main =
    Html.program
        { init = init
        , view = L.View.view
        , update = update
        , subscriptions =
            (\_ -> Sub.none)
        }


type Msg
    = NOOP


type alias Model =
    {}


init =
    Return.singleton {}


update msg =
    Return.singleton
