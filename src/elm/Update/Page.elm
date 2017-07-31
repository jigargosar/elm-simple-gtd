module Update.Page exposing (Config, update)

import Models.Selection
import Page exposing (..)
import Pages.EntityList
import Return
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
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
        setMaybePage page =
            page ?|> (PageMsg_SetPage >> update config) ?= identity
    in
    case msg of
        PageMsg_SetPage page ->
            map (\model -> { model | page = page })
                >> map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        PageMsg_SetEntityListPage listView ->
            listView |> Old_EntityListPage >> PageMsg_SetPage >> update config

        PageMsg_NavigateToPath path ->
            case path of
                "custom-sync" :: [] ->
                    CustomSyncSettingsPage "Advance Settings"
                        |> Just
                        |> setMaybePage

                _ ->
                    Pages.EntityList.initialModel path
                        ?|> EntityListPage
                        |> setMaybePage
