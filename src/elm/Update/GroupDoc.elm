module Update.GroupDoc exposing (Config, update)

import Document
import ExclusiveMode.Types exposing (ExclusiveMode(XMGroupDocForm))
import GroupDoc
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditGroupDocForm)
import Models.GroupDocStore exposing (contextStore, projectStore)
import Msg.GroupDoc exposing (..)
import Return
import Set
import Store
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import Types.GroupDoc exposing (..)
import X.Record exposing (Field, fieldLens, overReturn, overT2)
import X.Return exposing (..)


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


type alias Config msg a =
    { a
        | onSetExclusiveMode : ExclusiveMode -> msg
        , revertExclusiveMode : msg
    }


update :
    Config msg a
    -> GroupDocMsg
    -> SubReturnF msg model
update config msg =
    case msg of
        OnGroupDocAction gdType groupDocAction ->
            case groupDocAction of
                GDA_StartAdding ->
                    createAddGroupDocForm gdType
                        |> XMGroupDocForm
                        >> config.onSetExclusiveMode
                        >> returnMsgAsCmd

        OnSaveGroupDocForm form ->
            onGroupDocIdAction config form.groupDocId (GDA_SaveForm form)

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
                >> returnMsgAsCmd config.revertExclusiveMode
    in
    case groupDocIdAction of
        GDA_StartEditing ->
            X.Return.returnWithMaybe1
                (Models.GroupDocStore.findGroupDocById groupDocId)
                (createEditGroupDocForm gdType
                    >> XMGroupDocForm
                    >> config.onSetExclusiveMode
                    >> returnMsgAsCmd
                )

        GDA_ToggleArchived ->
            updateGroupDocHelp GroupDoc.toggleArchived

        GDA_ToggleDeleted ->
            updateGroupDocHelp Document.toggleDeleted

        GDA_UpdateFormName form newName ->
            GroupDoc.Form.setName newName form
                |> XMGroupDocForm
                |> config.onSetExclusiveMode
                |> returnMsgAsCmd

        GDA_SaveForm form ->
            case form.mode of
                GDFM_Add ->
                    insertGroupDoc form.groupDocType form.name

                GDFM_Edit ->
                    updateGroupDocHelp (GroupDoc.setName form.name)


insertGroupDoc gdType name =
    let
        store =
            Models.GroupDocStore.storeFieldFromGDType gdType
    in
    andThen
        (\model ->
            overReturn store (Store.insertAndPersist (GroupDoc.init name model.now)) model
        )


updateContext id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn contextStore


updateProject id updateFn =
    updateAllNamedDocsDocs (Set.singleton id) updateFn projectStore


updateAllGroupDocs gdType updateFn idSet model =
    overReturn (Models.GroupDocStore.storeFieldFromGDType gdType)
        (Store.updateAndPersist
            (Document.getId >> Set.member # idSet)
            model.now
            updateFn
        )
        model


updateAllNamedDocsDocs idSet updateFn store model =
    overReturn store
        (Store.updateAndPersist
            (Document.getId >> Set.member # idSet)
            model.now
            updateFn
        )
        model
