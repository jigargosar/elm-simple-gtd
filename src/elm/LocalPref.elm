module LocalPref exposing (decode, encodeLocalPref)

import AppDrawer.Model
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import Toolkit.Operators exposing (..)
import Types.LocalPref exposing (..)
import X.Function.Infix exposing (..)


localPrefDecoder =
    D.succeed LocalPref
        |> D.optional "appDrawer" AppDrawer.Model.decoder AppDrawer.Model.default



--encodeLocalPref : AppModel -> E.Value


encodeLocalPref model =
    E.object
        [ "appDrawer" => AppDrawer.Model.encoder model.appDrawerModel
        ]


defaultLocalPref : LocalPref
defaultLocalPref =
    { appDrawer = AppDrawer.Model.default
    }


decode encoded =
    D.decodeValue localPrefDecoder encoded
        |> Result.mapError (Debug.log "Unable to decode localPref")
        != defaultLocalPref
