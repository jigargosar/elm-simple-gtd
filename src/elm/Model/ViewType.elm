module Model.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import ViewType exposing (ViewType(EntityListView))


maybeGetEntityListViewType model =
    case model.viewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


getMainViewType =
    .viewType


defaultView =
    EntityListView Entity.Types.defaultViewType
