module Update.ViewType exposing (Config, update)

import Document.Types exposing (DocId)
import Entity.Types exposing (EntityListViewType(ContextsView))
import Model.Selection
import Msg.ViewType exposing (..)
import Return
import Set exposing (Set)
import Types.ViewType exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | viewType : ViewType
        , selectedEntityIdSet : Set DocId
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg =
    { noop : msg
    }


update :
    Config msg
    -> ViewTypeMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        SwitchView viewType ->
            map (switchToView viewType)
                >> map Model.Selection.clearSelection

        SwitchToEntityListView listView ->
            listView |> EntityListView >> SwitchView >> update config

        SwitchToContextsView ->
            ContextsView |> SwitchToEntityListView >> update config


switchToView viewType model =
    { model | viewType = viewType }
