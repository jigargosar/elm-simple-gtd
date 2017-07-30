module Msg.GroupDoc exposing (..)

import Types.GroupDoc exposing (..)


type GroupDocMsg
    = OnGroupDocAction GroupDocType GroupDocAction
    | OnSaveGroupDocForm GroupDocForm
    | OnGroupDocIdAction GroupDocId GroupDocIdAction


updateGroupDocFromNameMsg : GroupDocForm -> GroupDocName -> GroupDocMsg
updateGroupDocFromNameMsg form newName =
    OnGroupDocIdAction form.groupDocId (GDA_UpdateFormName form newName)


onToggleGroupDocArchived groupDocId =
    OnGroupDocIdAction groupDocId GDA_ToggleArchived


onStartEditingGroupDoc groupDocId =
    OnGroupDocIdAction groupDocId GDA_StartEditing
