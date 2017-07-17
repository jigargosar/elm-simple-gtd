module Update.GroupDoc exposing (..)

import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity)
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(..))
import GroupDoc.Types exposing (ContextStore, GroupDocType(..), ProjectStore)
import Model.GroupDocStore
import Msg.GroupDoc exposing (..)
import Return exposing (andThen)
import Set
import Store
import Stores
import Todo.Types exposing (TodoStore)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Tuple2
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Time exposing (Time)
import ViewType exposing (ViewType)
import X.Record exposing (overT2)


type alias SubModel model =
    { model
        | todoStore : TodoStore
        , projectStore : ProjectStore
        , contextStore : ContextStore
        , now : Time
        , focusInEntity : Entity
        , mainViewType : ViewType
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg model =
    { updateEntityListCursorOnGroupDocChange : SubReturnF msg model
    }


update :
    Config msg model
    -> GroupDocMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnSaveGroupDocForm form ->
            let
                update fn =
                    fn form.id (GroupDoc.setName form.name)
                        |> andThen
            in
                (case form.groupDocType of
                    ContextGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                insertContext form.name

                            GDFM_Edit ->
                                update updateContext

                    ProjectGroupDoc ->
                        case form.mode of
                            GDFM_Add ->
                                insertProject form.name

                            GDFM_Edit ->
                                update updateProject
                )
                    >> config.updateEntityListCursorOnGroupDocChange

        -- todo: remove duplication, very error prone.
        OnToggleContextArchived id ->
            (updateContext id GroupDoc.toggleArchived
                |> andThen
            )
                >> config.updateEntityListCursorOnGroupDocChange

        OnToggleProjectArchived id ->
            (updateProject id GroupDoc.toggleArchived
                |> andThen
            )
                >> config.updateEntityListCursorOnGroupDocChange

        OnToggleContextDeleted id ->
            (updateContext id Document.toggleDeleted
                |> andThen
            )
                >> config.updateEntityListCursorOnGroupDocChange

        OnToggleProjectDeleted id ->
            (updateProject id Document.toggleDeleted
                |> andThen
            )
                >> config.updateEntityListCursorOnGroupDocChange


contextStore =
    Model.GroupDocStore.contextStore


projectStore =
    Model.GroupDocStore.projectStore


insertProject name =
    insertGroupDoc name projectStore updateProject


insertContext name =
    insertGroupDoc name contextStore updateContext


insertGroupDoc name store updateFn =
    andThen
        (\model ->
            overT2 store (Store.insert (GroupDoc.init name model.now)) model
                |> (\( gd, model ) -> updateFn (getDocId gd) identity model)
        )



--updateContext : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore



--updateProject : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateAllNamedDocsDocs idSet updateFn store model =
    X.Record.overT2 store
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
        |> Tuple2.swap
