module Main.View exposing (elmAppView)

import DecodeExtra exposing (traceDecoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Events.Extra exposing (onClickStopPropagation)
import Json.Decode
import Json.Encode
import Main.Model exposing (..)
import Main.Msg exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)


elmAppView m =
    div []
        [ text "Hello"
        ]
