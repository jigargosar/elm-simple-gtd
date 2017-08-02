module Update.Page exposing (Config, update)

import Document exposing (..)
import Models.Selection
import Page exposing (..)
import Pages.EntityList
import Return
import Set exposing (Set)
import Toolkit.Operators exposing (..)
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
            map (\model -> { model | page = page })
                >> map Models.Selection.clearSelection
                >> returnMsgAsCmd config.revertExclusiveMode

        setMaybePage page =
            page ?|> setPage ?= identity
    in
    case msg of
        PageMsg_NavigateToPath path ->
            case path of
                _ ->
                    Pages.EntityList.initFromPath path
                        ?|> EntityListPage
                        |> setMaybePage
