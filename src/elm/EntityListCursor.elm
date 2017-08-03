module EntityListCursor exposing (..)

import Entity exposing (..)
import Pages.EntityList


type alias EntityListCursor =
    { entityIdList : List EntityId
    , maybeEntityIdAtCursor : Maybe EntityId
    , entityListPageModel : Pages.EntityList.PageModel
    }


type alias HasEntityListCursor a =
    { a | entityListCursor : EntityListCursor }


getMaybeEntityIdAtCursor__ model =
    model.entityListCursor.maybeEntityIdAtCursor


entityListCursorInitialValue : EntityListCursor
entityListCursorInitialValue =
    { entityIdList = []
    , maybeEntityIdAtCursor = Nothing
    }
