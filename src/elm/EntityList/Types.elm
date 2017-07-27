module EntityList.Types exposing (..)

import Entity.Types exposing (EntityId)


type alias EntityList =
    { idList : List EntityId
    , maybeFocusableEntityId : Maybe EntityId
    }


type alias HasEntityList a =
    { a | entityList : EntityList }
