module Model.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Types.ViewType exposing (ViewType(EntityListView))


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
