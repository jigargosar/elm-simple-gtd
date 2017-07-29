module Page exposing (..)

import Entity.Types exposing (EntityListPageModel)


type Page
    = EntityListPage EntityListPageModel
    | CustomSyncSettingsPage


type ViewTypeMsg
    = SwitchView Page
    | SwitchToEntityListView EntityListPageModel


maybeGetEntityListViewType model =
    case model.viewType of
        EntityListPage viewType ->
            Just viewType

        _ ->
            Nothing


getViewType =
    .viewType


defaultView =
    EntityListPage Entity.Types.defaultViewType
