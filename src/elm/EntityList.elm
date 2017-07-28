module EntityList exposing (..)

import Entity.Types exposing (EntityId)
import X.Record exposing (..)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeFocusableEntityId : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


entityListCursor =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeFocusableEntityId = Nothing
    }
