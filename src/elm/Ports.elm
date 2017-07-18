port module Ports exposing (..)

import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


port onFirebaseDatabaseChange : (( String, E.Value ) -> msg) -> Sub msg


onFirebaseDatabaseChangeSub tagger =
    onFirebaseDatabaseChange (uncurry tagger)
