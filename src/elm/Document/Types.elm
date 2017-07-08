module Document.Types exposing (..)

import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


type alias Id =
    String


type alias Revision =
    String


type alias DeviceId =
    String


type alias Document record =
    { record
        | id : Id
        , rev : Revision
        , deleted : Bool
        , createdAt : Time
        , modifiedAt : Time
        , deviceId : DeviceId
    }
