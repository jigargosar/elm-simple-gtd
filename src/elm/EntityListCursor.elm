module EntityListCursor exposing (..)

import Entity.Types exposing (EntityId)
import X.Record exposing (..)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


entityListCursor =
    fieldLens .entityListCursor (\s b -> { b | entityListCursor = s })


getMaybeEntityIdAtCursor model =
    model.entityListCursor.maybeEntityIdAtCursor


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    }
