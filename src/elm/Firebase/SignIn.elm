module Firebase.SignIn exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record


type State
    = FirstVisitNotSignedIn
    | SkipSignIn
    | SignInSuccess
    | TriedSignOut


stringToMaybeState string =
    case string of
        "SkipSignIn" ->
            Just SkipSignIn

        "TriedSignOut" ->
            Just TriedSignOut

        "SignInSuccess" ->
            Just SignInSuccess

        "FirstVisitNotSignedIn" ->
            Just FirstVisitNotSignedIn

        _ ->
            Nothing


stateDecoder : Decoder State
stateDecoder =
    D.string
        |> D.andThen
            (\string ->
                string |> stringToMaybeState ?|> D.succeed ?= D.fail ("Unknown State: " ++ string)
            )


type alias SignInModel =
    { state : State
    }


type alias SignInModelF =
    SignInModel -> SignInModel


state =
    X.Record.fieldLens .state (\s b -> { b | state = s })


decoder : Decoder SignInModel
decoder =
    D.succeed SignInModel
        |> D.required "state" stateDecoder


encode : SignInModel -> E.Value
encode model =
    E.object
        [ "state" => E.string (toString model.state)
        ]


default : SignInModel
default =
    { state = FirstVisitNotSignedIn
    }


shouldSkipSignIn model =
    case model.state of
        SignInSuccess ->
            True

        SkipSignIn ->
            True

        _ ->
            False


setSkipSignIn =
    X.Record.set state SkipSignIn


setStateToTriedSignOut =
    X.Record.set state TriedSignOut


setStateToSignInSuccess =
    X.Record.set state SignInSuccess
