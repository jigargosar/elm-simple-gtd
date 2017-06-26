module Firebase.User exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D


type alias Model =
    { id : String
    , providerData : List Provider
    }


type alias Provider =
    { displayName : String
    , email : String
    , photoURL : String
    , providerId : String
    , uid : String
    }


providerDataDecoder =
    D.succeed Provider
        |> D.required "displayName" D.string
        |> D.required "email" D.string
        |> D.required "photoURL" D.string
        |> D.required "providerId" D.string
        |> D.required "uid" D.string


decoder =
    D.succeed Model
        |> D.required "uid" D.string
        |> D.required "providerData" (D.list providerDataDecoder)
