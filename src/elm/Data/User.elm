module Data.User exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


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
