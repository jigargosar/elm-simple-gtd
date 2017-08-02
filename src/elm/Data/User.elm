module Data.User exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D


type alias MaybeUser =
    Maybe User


type alias UID =
    String


type alias User =
    { id : UID
    , displayName : String
    , email : String
    , photoURL : String
    }


decoder =
    D.succeed User
        |> D.required "uid" D.string
        |> D.required "displayName" D.string
        |> D.required "email" D.string
        |> D.required "photoURL" D.string


maybeUserDecoder : Decoder MaybeUser
maybeUserDecoder =
    D.maybe decoder
