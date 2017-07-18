module Msg.ViewType exposing (..)

import Entity.Types exposing (EntityListViewType)
import Types.ViewType exposing (ViewType)


type ViewTypeMsg
    = SwitchView ViewType
    | SwitchToEntityListView EntityListViewType
    | SwitchToContextsView
