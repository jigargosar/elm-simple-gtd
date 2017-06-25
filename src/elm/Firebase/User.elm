module Firebase.User exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias UserModel =
    { id : String
    , providerData : List ProviderData
    }


type alias ProviderData =
    { displayName : String
    , email : String
    , photoURL : String
    , providerId : String
    , uid : String
    }


providerDataDecoder =
    D.succeed ProviderData
        |> D.required "displayName" D.string
        |> D.required "email" D.string
        |> D.required "photoURL" D.string
        |> D.required "providerId" D.string
        |> D.required "uid" D.string


decoder =
    D.succeed UserModel
        |> D.required "uid" D.string
        |> D.required "providerData" (D.list providerDataDecoder)
