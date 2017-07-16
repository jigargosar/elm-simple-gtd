module Update.MainViewType exposing (..)

import Return exposing (andThen, map)
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
