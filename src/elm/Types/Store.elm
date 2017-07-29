module Types.Store exposing (..)

import Dict exposing (Dict)
import Document
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import List.Extra as List
import Random.Pcg
import Set exposing (Set)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import Types.Document exposing (..)
import X.Debug
import X.Random
import X.Record as Record exposing (get, over, overT2)


type alias Store x =
    { seed : Random.Pcg.Seed
    , dict : Dict DocId (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }
