module Update.MainViewType exposing (..)

import Model.Selection
import Model.ViewType
import Return exposing (andThen, map)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Msg.ViewType exposing (..)
import ViewType exposing (..)


update config msg =
    case msg of
        SwitchView viewType ->
            map (switchToView viewType)
                >> config.clearSelection

        SwitchToEntityListView listView ->
            listView |> EntityListView >> SwitchView >> update config


switchToView mainViewType model =
    { model | mainViewType = mainViewType }
