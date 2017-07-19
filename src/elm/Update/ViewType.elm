module Update.ViewType exposing (Config, update)

import Entity.Types exposing (EntityListViewType(ContextsView))
import Return exposing (andThen, map)
import Msg.ViewType exposing (..)
import Types.ViewType exposing (..)


type alias SubModel model =
    { model | viewType : ViewType }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config a msg model =
    { a
        | clearSelection : SubReturnF msg model
    }


update :
    Config a msg model
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
