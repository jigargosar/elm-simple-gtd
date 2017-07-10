module L.Main exposing (..)

import Html
import L.View
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
