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
    = TriedSignIn
    | TriedSignOut
    | SignInSuccess
    | SignOutSuccess


stringToMaybeState string =
    case string of
        "TriedSignIn" ->
            Just TriedSignIn

        "TriedSignOut" ->
            Just TriedSignOut

        "SignInSuccess" ->
            Just SignInSuccess

        "SignOutSuccess" ->
            Just SignOutSuccess

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
    , state = SignOutSuccess
    }


shouldSkipSignIn =
    .skipSignIn


updateOnTriedSignIn =
    X.Record.over state updateStateOnTriedSignIn


updateStateOnTriedSignIn state =
    case state of
        _ ->
            TriedSignIn


updateOnTriedSignOut =
    X.Record.over state updateStateOnTriedSignOut


updateStateOnTriedSignOut state =
    case state of
        _ ->
            TriedSignOut


updateAfterUserChanged user =
    X.Record.over state (updateStateAfterUserChanged user)


updateStateAfterUserChanged user state =
    case ( state, user ) of
        ( TriedSignIn, Firebase.SignedIn _ ) ->
            SignInSuccess

        ( TriedSignOut, Firebase.SignedOut ) ->
            SignOutSuccess

        _ ->
            state
