module EntityListCursor exposing (..)

import Entity exposing (..)


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


getMaybeEntityIdAtCursor__ model =
    model.entityListCursor.maybeEntityIdAtCursor


initialValue : EntityListCursor
initialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    }
