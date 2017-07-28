module EntityList exposing (..)

import Entity.Types exposing (EntityId)
import X.Record exposing (..)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeFocusableEntityId : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityList : EntityListCursor }


entityListCursor =
    fieldLens .entityList (\s b -> { b | entityList = s })


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeFocusableEntityId = Nothing
    }
