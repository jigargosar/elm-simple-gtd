module Model.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Types.View exposing (ViewType(EntityListView))


maybeGetEntityListViewType model =
    case model.mainViewType of
        EntityListView viewType ->
            Just viewType

        _ ->
            Nothing


getMainViewType =
    .mainViewType


defaultView =
    EntityListView ContextsView
