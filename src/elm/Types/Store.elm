module Types.Store exposing (..)

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Random.Pcg
import Types.Document exposing (..)


type alias Store x =
    { seed : Random.Pcg.Seed
    , dict : Dict DocId (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }
