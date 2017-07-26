module Model.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import ViewType exposing (ViewType(EntityListView))


maybeGetEntityListViewType model =
    case model.viewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


getViewType =
    .viewType


defaultView =
    EntityListView Entity.Types.defaultViewType
