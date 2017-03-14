module Main.Msg exposing (..)

import Json.Decode
import Navigation exposing (Location)


type Msg
    = LocationChanged Location
