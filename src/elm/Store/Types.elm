module Store.Types exposing (..)

import Dict exposing (Dict)
import Document exposing (DeviceId, DocId, Document)
import Json.Decode exposing (Decoder)
import Json.Encode as E
import Random.Pcg exposing (Seed)


type alias Store x =
    { seed : Seed
    , dict : Dict DocId (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }
