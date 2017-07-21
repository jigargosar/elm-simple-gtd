module L.Main exposing (..)

import Html
import L.View
import Return


main =
    Html.beginnerProgram
        { model = ()
        , view = L.View.view
        , update = update
        }


type Msg
    = NOOP


update msg =
    identity
