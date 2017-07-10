module LocalPref exposing (..)

import AppDrawer.Model
import Firebase.SignIn
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Types exposing (LocalPref)
import X.Function.Infix exposing (..)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


localPrefDecoder =
    D.succeed LocalPref
        |> D.optional "appDrawer" AppDrawer.Model.decoder AppDrawer.Model.default
        |> D.optional "signIn" Firebase.SignIn.decoder Firebase.SignIn.default


encodeLocalPref model =
    E.object
        [ "appDrawer" => AppDrawer.Model.encoder model.appDrawerModel
        , "signIn" => Firebase.SignIn.encode model.signInModel
        ]


defaultLocalPref : LocalPref
defaultLocalPref =
    { appDrawer = AppDrawer.Model.default
    , signIn = Firebase.SignIn.default
    }


decode encoded =
    D.decodeValue localPrefDecoder encoded
        |> Result.mapError (Debug.log "Unable to decode localPref")
        != defaultLocalPref
