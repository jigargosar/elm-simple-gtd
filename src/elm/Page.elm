module Page exposing (..)

import Entity.Types exposing (..)
import Pages.EntityList exposing (..)


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
    EntityListPage Pages.EntityList.defaultPage
