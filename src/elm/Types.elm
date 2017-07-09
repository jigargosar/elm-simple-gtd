module Types exposing (..)

import Entity.Types exposing (EntityListViewType)


type ViewType
    = EntityListView EntityListViewType
    | SyncView
