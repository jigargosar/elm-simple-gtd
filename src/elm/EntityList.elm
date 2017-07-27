module EntityList exposing (..)

import Entity.Types exposing (EntityId)
import X.Record exposing (..)


type alias EntityListModel =
    { entityIdList : List EntityId
    , maybeFocusableEntityId : Maybe EntityId
    }


type alias HasEntityListModel a =
    { a | entityList : EntityListModel }


entityList =
    fieldLens .entityList (\s b -> { b | entityList = s })


initialValue : EntityListModel
initialValue =
    { entityIdList = []
    , maybeFocusableEntityId = Nothing
    }
