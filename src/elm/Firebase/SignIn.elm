module Firebase.SignIn exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias Model =
    { skipSignIn : Bool
    }


decode =
    D.succeed Model
        |> D.required "skipSignIn" D.bool


encode model =
    E.object
        [ "skipSignIn" => E.bool model.skipSignIn
        ]


default =
    { skipSignIn = False }


shouldSkipSignIn =
    .skipSignIn
