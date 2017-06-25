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


type State
    = TriedSignIn
    | TriedSignOut
    | SignedIn
    | SignedOut


stringToMaybeState string =
    case string of
        "TriedSignIn" ->
            Just TriedSignIn

        "TriedSignOut" ->
            Just TriedSignOut

        "SignedIn" ->
            Just SignedIn

        "SignedOut" ->
            Just SignedOut

        _ ->
            Nothing


stateDecoder : Decoder State
stateDecoder =
    D.string
        |> D.andThen
            (\string ->
                string |> stringToMaybeState ?|> D.succeed ?= D.fail ("Unknown State: " ++ string)
            )


type alias Model =
    { skipSignIn : Bool
    , state : State
    }


decoder : Decoder Model
decoder =
    D.succeed Model
        |> D.required "skipSignIn" D.bool
        |> D.required "state" stateDecoder


encode : Model -> E.Value
encode model =
    E.object
        [ "skipSignIn" => E.bool model.skipSignIn
        , "state" => E.string (toString model.state)
        ]


default : Model
default =
    { skipSignIn = False
    , state = SignedOut
    }


shouldSkipSignIn =
    .skipSignIn
