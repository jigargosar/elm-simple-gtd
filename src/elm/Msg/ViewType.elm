module Msg.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType)
import Types.View exposing (ViewType)


type ViewTypeMsg
    = SwitchView ViewType
    | SwitchToEntityListView EntityListViewType
    | SwitchToContextsView
