module Update.Page exposing (Config, update)

import Document exposing (DocId)
import Model.Selection
import Page exposing (..)
import Return
import Set exposing (Set)
import X.Return exposing (..)


type alias SubModel model =
    { model
        | page : Page
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
    -> PageMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        SwitchView page ->
            map (setPage page)
                >> map Model.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        SwitchToEntityListView listView ->
            listView |> EntityListPage >> SwitchView >> update config


setPage page model =
    { model | page = page }