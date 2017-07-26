module Update.ViewType exposing (Config, update)

import Document exposing (DocId)
import Model.Selection
import Return
import Set exposing (Set)
import ViewType exposing (..)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | viewType : ViewType
        , selectedEntityIdSet : Set DocId
    }


type alias SubReturnF msg model =
    Return.ReturnF msg (SubModel model)


type alias Config msg a =
    { a
        | revertExclusiveMode : msg
    }


update :
    Config msg a
    -> ViewTypeMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        SwitchView viewType ->
            map (setViewType viewType)
                >> map Model.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        SwitchToEntityListView listView ->
            listView |> EntityListView >> SwitchView >> update config


setViewType viewType model =
    { model | viewType = viewType }
