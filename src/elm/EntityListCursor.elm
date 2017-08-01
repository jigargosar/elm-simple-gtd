module EntityListCursor exposing (..)

import Entity
import Entity.Types exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.List


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
