module Update.GroupDoc exposing (update)

import Document
import Document.Types exposing (getDocId)
import ExclusiveMode.Types exposing (ExclusiveMode)
import GroupDoc
import GroupDoc.FormTypes exposing (GroupDocFormMode(..))
import GroupDoc.Types exposing (..)
import Model.GroupDocStore exposing (contextStore, projectStore)
import Msg.GroupDoc exposing (..)
import Return exposing (andThen)
import Set
import Store
import Toolkit.Operators exposing (..)
import Tuple2
import Time exposing (Time)
import X.Function exposing (applyWith)
import X.Record exposing (Field, fieldLens, overReturn, overT2)


type alias SubModel model =
    { model
        | projectStore : ProjectStore
        , contextStore : ContextStore
        , now : Time
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg model =
    { onSetExclusiveMode : ExclusiveMode -> SubReturnF msg model
    }


update :
    {- Config msg model
       ->
    -}
    GroupDocMsg
    -> SubReturnF msg model
update msg =
    case msg of
        OnSaveGroupDocForm form ->
            case form.mode of
                GDFM_Add ->
                    insertGroupDoc form.groupDocType form.name

                GDFM_Edit ->
                    updateGroupDoc form.groupDocType
                        form.id
                        (GroupDoc.setName form.name)

        OnToggleContextDeleted id ->
            updateContext id Document.toggleDeleted |> andThen

        OnToggleProjectDeleted id ->
            updateProject id Document.toggleDeleted |> andThen

        OnGroupDocIdAction groupDocId groupDocIdAction ->
            onGroupDocIdAction groupDocId groupDocIdAction


onGroupDocIdAction groupDocId groupDocIdAction =
    let
        ( gdType, id ) =
            case groupDocId of
                ContextGroupDocId id ->
                    ( ContextGroupDocType, id )

                ProjectGroupDocId id ->
                    ( ProjectGroupDocType, id )

        updateGroupDocHelp updateFn =
            updateAllGroupDocs gdType updateFn (Set.singleton id) |> andThen
    in
        case groupDocIdAction of
            GDA_ToggleArchived ->
                updateGroupDocHelp GroupDoc.toggleArchived

            GDA_ToggleDeleted ->
                updateGroupDocHelp Document.toggleDeleted

            GDA_SetFormName name ->
                {- GroupDoc.Form.setName newName form
                   |> XMGroupDocForm
                   >> config.onSetExclusiveMode
                -}
                identity


insertGroupDoc gdType name =
    let
        store =
            (Model.GroupDocStore.storeFieldFromGDType gdType)
    in
        andThen
            (\model ->
                overReturn store (Store.insertAndPersist (GroupDoc.init name model.now)) model
            )



--updateContext : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore



--updateProject : DocId -> (GroupDoc -> GroupDoc) -> ModelReturnF


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateGroupDoc gdType id updateFn =
    updateAllGroupDocs gdType updateFn (Set.singleton id) |> andThen


updateAllGroupDocs gdType updateFn idSet model =
    overReturn (Model.GroupDocStore.storeFieldFromGDType gdType)
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model


updateAllNamedDocsDocs idSet updateFn store model =
    overReturn store
        (Store.updateAndPersist
            (getDocId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
