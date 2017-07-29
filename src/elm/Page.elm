module Page exposing (..)

import Entity.Types exposing (EntityListPageModel)


type Page
    = EntityListPage EntityListPageModel
    | CustomSyncSettingsPage


type PageMsg
    = SwitchView Page
    | SwitchToEntityListView EntityListPageModel


maybeGetEntityListPage model =
    case model.page of
        EntityListPage page ->
            Just page

        _ ->
            Nothing


getPage =
    .page


initialPage =
    EntityListPage Entity.Types.defaultPage
