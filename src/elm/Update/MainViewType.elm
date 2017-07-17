module Update.MainViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Return exposing (andThen, map)
import Msg.ViewType exposing (..)
import Update.Types exposing (SubReturnF)
import ViewType exposing (..)


type alias Config msg =
    { clearSelection : SubReturnF msg
    }


update :
    Config msg
    -> ViewTypeMsg
    -> SubReturnF msg
update config msg =
    case msg of
        SwitchView viewType ->
            map (switchToView viewType)
                >> config.clearSelection

        SwitchToEntityListView listView ->
            listView |> EntityListView >> SwitchView >> update config

        SwitchToContextsView ->
            ContextsView |> SwitchToEntityListView >> update config


switchToView mainViewType model =
    { model | mainViewType = mainViewType }
