module Store.Types exposing (..)

import Dict exposing (Dict)
import Document.Types exposing (DeviceId, DocId, Document)
import Json.Decode exposing (Decoder)
import Random.Pcg exposing (Seed)
import Json.Encode as E


type alias Store x =
    { seed : Seed
    , dict : Dict DocId (Document x)
    , otherFieldsEncoder : Document x -> List ( String, E.Value )
    , decoder : Decoder (Document x)
    , name : String
    , deviceId : DeviceId
    }
