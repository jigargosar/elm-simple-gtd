module Update.MainViewType exposing (..)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Return exposing (andThen, map)
import Msg.ViewType exposing (..)
import ViewType exposing (..)


type alias SubModel model =
    { model | mainViewType : ViewType }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg model =
    { clearSelection : SubReturnF msg model
    }


update :
    Config msg model
    -> ViewTypeMsg
    -> SubReturnF msg model
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
