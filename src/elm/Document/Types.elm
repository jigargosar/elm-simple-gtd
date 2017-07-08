module Document.Types exposing (..)

import Time exposing (Time)


type alias DocId =
    String


type alias Revision =
    String


type alias DeviceId =
    String


type alias Document record =
    { record
        | id : DocId
        , rev : Revision
        , deleted : Bool
        , createdAt : Time
        , modifiedAt : Time
        , deviceId : DeviceId
    }


getDocId =
    .id
