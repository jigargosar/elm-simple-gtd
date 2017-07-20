module Update.GroupDoc exposing (Config, update)

import Document
import Document.Types exposing (getDocId)
import ExclusiveMode.Types exposing (ExclusiveMode(XMGroupDocForm))
import GroupDoc
import GroupDoc.Form
import GroupDoc.Types exposing (GroupDocFormMode(..))
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
    , revertExclusiveMode : SubReturnF msg model
    }


update :
    Config msg model
    -> GroupDocMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnSaveGroupDocForm form ->
            onGroupDocIdAction config form.groupDocId (GDA_SaveForm form)

        OnToggleContextDeleted id ->
            updateContext id Document.toggleDeleted |> andThen

        OnToggleProjectDeleted id ->
            updateProject id Document.toggleDeleted |> andThen

        OnGroupDocIdAction groupDocId groupDocIdAction ->
            onGroupDocIdAction config groupDocId groupDocIdAction


onGroupDocIdAction config groupDocId groupDocIdAction =
    let
        ( gdType, id ) =
            case groupDocId of
                ContextGroupDocId id ->
                    ( ContextGroupDocType, id )

                ProjectGroupDocId id ->
                    ( ProjectGroupDocType, id )

        updateGroupDocHelp updateFn =
            (updateAllGroupDocs gdType updateFn (Set.singleton id) |> andThen)
                >> config.revertExclusiveMode
    in
        case groupDocIdAction of
            GDA_ToggleArchived ->
                updateGroupDocHelp GroupDoc.toggleArchived

            GDA_ToggleDeleted ->
                updateGroupDocHelp Document.toggleDeleted

            GDA_UpdateFormName form newName ->
                GroupDoc.Form.setName newName form
                    |> XMGroupDocForm
                    |> config.onSetExclusiveMode

            GDA_SaveForm form ->
                case form.mode of
                    GDFM_Add ->
                        insertGroupDoc form.groupDocType form.name

                    GDFM_Edit ->
                        updateGroupDocHelp (GroupDoc.setName form.name)


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
