module Msg.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType)
import ViewType exposing (ViewType)


type ViewTypeMsg
    = SwitchView ViewType
    | SwitchToEntityListView EntityListViewType
    | SwitchToContextsView
