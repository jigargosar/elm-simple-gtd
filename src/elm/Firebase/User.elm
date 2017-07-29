module Firebase.User exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Types.Firebase exposing (..)


providerDataDecoder =
    D.succeed Provider
        |> D.required "displayName" D.string
        |> D.required "email" D.string
        |> D.required "photoURL" D.string
        |> D.required "providerId" D.string
        |> D.required "uid" D.string


decoder =
    D.succeed UserInfo
        |> D.required "uid" D.string
        |> D.required "providerData" (D.list providerDataDecoder)
