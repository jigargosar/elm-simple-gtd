module ViewType exposing (..)

import Entity.Types exposing (EntityListViewType)


type ViewType
    = EntityListView EntityListViewType
    | SyncView


type ViewTypeMsg
    = SwitchView ViewType
    | SwitchToEntityListView EntityListViewType