module ViewType exposing (..)

import Entity.Types exposing (EntityListViewType)


type ViewType
    = EntityListView EntityListViewType
    | SyncView
