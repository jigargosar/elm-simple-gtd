module Update.GroupDoc exposing (..)

import Document
import ExclusiveMode.Types exposing (ExclusiveMode(XMGroupDocForm))
import GroupDoc exposing (..)
import GroupDoc.Form exposing (createAddGroupDocForm, createEditContextForm, createEditGroupDocForm)
import Models.GroupDocStore exposing (contextStore, projectStore)
import Return
import Set
import Store
import Time exposing (Time)
import Toolkit.Operators exposing (..)
import X.Record exposing (FieldLens, fieldLens, overReturn, overT2)
import X.Return exposing (..)


type GroupDocMsg
    = OnGroupDocAction GroupDocType GroupDocAction
    | OnSaveGroupDocForm GroupDocForm
    | OnGroupDocIdAction GroupDocId GroupDocIdAction


updateGroupDocFromNameMsg : GroupDocForm -> GroupDocName -> GroupDocMsg
updateGroupDocFromNameMsg form newName =
    OnGroupDocIdAction form.groupDocId (GDA_UpdateFormName form newName)


toggleGroupDocArchivedMsg groupDocId =
    OnGroupDocIdAction groupDocId GDA_ToggleArchived


startEditingGroupDocMsg groupDocId =
    OnGroupDocIdAction groupDocId GDA_StartEditing


type alias SubModel model =
    { model
        | projectStore : ProjectStore
        , contextStore : ContextStore
    }


type alias SubReturn msg model =
    Return.Return msg (SubModel model)


type alias SubReturnF msg model =
    SubReturn msg model -> SubReturn msg model


type alias Config msg a =
    { a
        | onSetExclusiveMode : ExclusiveMode -> msg
        , revertExclusiveModeMsg : msg
    }


update :
    Config msg a
    -> Time
    -> GroupDocMsg
    -> SubReturnF msg model
update config now msg =
    case msg of
        OnGroupDocAction gdType groupDocAction ->
            case groupDocAction of
                GDA_StartAdding ->
                    createAddGroupDocForm gdType
                        |> XMGroupDocForm
                        >> config.onSetExclusiveMode
                        >> returnMsgAsCmd

        OnSaveGroupDocForm form ->
            onGroupDocIdAction config now form.groupDocId (GDA_SaveForm form)

        OnGroupDocIdAction groupDocId groupDocIdAction ->
            onGroupDocIdAction config now groupDocId groupDocIdAction


onGroupDocIdAction config now groupDocId groupDocIdAction =
    let
        ( gdType, id ) =
            case groupDocId of
                GroupDocId ContextGroupDocType id ->
                    ( ContextGroupDocType, id )

                GroupDocId ProjectGroupDocType id ->
                    ( ProjectGroupDocType, id )

        updateGroupDocHelp updateFn =
            (updateAllGroupDocs now gdType updateFn (Set.singleton id) |> andThen)
                >> returnMsgAsCmd config.revertExclusiveModeMsg
    in
    case groupDocIdAction of
        GDA_StartEditing ->
            X.Return.returnWithMaybe1
                (Models.GroupDocStore.findByGroupDocId groupDocId)
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
                    insertGroupDoc now form.groupDocType form.name
                        >> returnMsgAsCmd config.revertExclusiveModeMsg

                GDFM_Edit ->
                    updateGroupDocHelp (GroupDoc.setName form.name)


insertGroupDoc now gdType name =
    let
        store =
            Models.GroupDocStore.storeFieldFromGDType gdType
    in
    andThen
        (\model ->
            overReturn store (Store.insertAndPersist (GroupDoc.init name now)) model
        )


updateAllGroupDocs now gdType updateFn idSet model =
    overReturn (Models.GroupDocStore.storeFieldFromGDType gdType)
        (Store.updateAndPersist
            (Document.getId >> Set.member # idSet)
            now
            updateFn
        )
        model
