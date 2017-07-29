module Types.Document exposing (..)

import Set exposing (Set)
import Time exposing (Time)


type alias DocId =
    String


type alias Revision =
    String


type alias DeviceId =
    String


type alias Deleted =
    Bool


type alias Document record =
    { record
        | id : DocId
        , rev : Revision
        , deleted : Deleted
        , createdAt : Time
        , modifiedAt : Time
        , deviceId : DeviceId
    }


type alias IdSet =
    Set DocId
