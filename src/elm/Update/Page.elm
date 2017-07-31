module Update.Page exposing (Config, update)

import Models.Selection
import Page exposing (..)
import Return
import Set exposing (Set)
import Types.Document exposing (..)
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
    let
        setPage page =
            PageMsg_SetPage page |> update config
    in
    case msg of
        PageMsg_SetPage page ->
            map (\model -> { model | page = page })
                >> map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        PageMsg_SetEntityListPage listView ->
            listView |> EntityListPage >> PageMsg_SetPage >> update config

        PageMsg_NavigateToPath path ->
            case path of
                "custom-sync" :: [] ->
                    CustomSyncSettingsPage "Custom Sync" |> setPage

                _ ->
                    identity
