module Data.Debug exposing (..)

import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E
import List.Extra as List
import Maybe.Extra as Maybe
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)


type DebugAction
    = DebugAction String


encode (DebugAction debugAction) =
    E.string debugAction


decoder =
    D.succeed DebugAction
