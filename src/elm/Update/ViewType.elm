module Update.ViewType exposing (Config, update)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Msg.ViewType exposing (..)
import Return
import Types.ViewType exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model | viewType : ViewType }


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


switchToView viewType model =
    { model | viewType = viewType }
