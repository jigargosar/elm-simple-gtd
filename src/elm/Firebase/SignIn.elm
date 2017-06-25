module Firebase.SignIn exposing (..)

import Firebase
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import X.Record


type State
    = TriedSignOut
    | SignInSuccess


stringToMaybeState string =
    case string of
        "TriedSignOut" ->
            Just TriedSignOut

        "SignInSuccess" ->
            Just SignInSuccess

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


state =
    X.Record.field .state (\s b -> { b | state = s })


skipSignIn =
    X.Record.field .skipSignIn (\s b -> { b | skipSignIn = s })


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
    , state = TriedSignOut
    }


shouldSkipSignIn model =
    --    .skipSignIn
    case model.state of
        SignInSuccess ->
            True

        _ ->
            False


setSkipSignIn =
    X.Record.set skipSignIn True


setStateToTriedSignOut =
    X.Record.set state TriedSignOut


setStateToSignInSuccess =
    X.Record.set state SignInSuccess
        >> X.Record.set skipSignIn False


updateAfterUserChanged user =
    X.Record.over state (updateStateAfterUserChanged user)


updateStateAfterUserChanged user state =
    case user of
        Firebase.SignedIn _ ->
            SignInSuccess

        _ ->
            state
