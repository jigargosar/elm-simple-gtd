module Ui.Helpers.Env exposing (..)

{-| Module for interacting with the environment variables.

# Functions
@docs get, getString
-}

import Json.Decode as Json
import Native.Env


{-| Gets the value of the given environment variable with a decoder and a
default value.

    case Ui.Helpers.Env.get "token" Json.Decode.string of
      Ok value -> value
      Err msg -> msg
-}
get : String -> Json.Decoder a -> Result String a
get key decoder =
  Json.decodeValue decoder (Native.Env.get key)


{-| Gets a string value of the given environment varaible.

    case Ui.Helpers.Env.getString "token" of
      Ok value -> value
      Err msg -> msg
-}
getString : String -> Result String String
getString name =
  get name Json.string
