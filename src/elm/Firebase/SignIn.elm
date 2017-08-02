module Firebase.SignIn exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Toolkit.Operators exposing (..)
import X.Function.Infix exposing (..)
import X.Record exposing (..)


type alias SignInModel =
    { showSignInDialog : Bool
    }


type alias SignInModelF =
    SignInModel -> SignInModel


showSignInDialog =
    X.Record.fieldLens .showSignInDialog (\s b -> { b | showSignInDialog = s })


decoder : Decoder SignInModel
decoder =
    D.succeed SignInModel
        |> D.optional "showSignInDialog" D.bool True


encode : SignInModel -> E.Value
encode model =
    E.object
        [ "showSignInDialog" => E.bool model.showSignInDialog
        ]


default : SignInModel
default =
    { showSignInDialog = True
    }


shouldSkipSignIn model =
    not model.showSignInDialog


setSkipSignIn =
    set showSignInDialog False


setStateToTriedSignOut =
    set showSignInDialog True


setStateToSignInSuccess =
    set showSignInDialog False
