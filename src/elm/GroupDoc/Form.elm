module GroupDoc.Form exposing (..)

import Document
import GroupDoc exposing (..)


createEditGroupDocForm : GroupDocType -> GroupDoc -> GroupDocForm
createEditGroupDocForm groupDocType groupDoc =
    let
        id =
            Document.getId groupDoc
    in
    { id = id
    , groupDocType = groupDocType
    , groupDocId = GroupDocId groupDocType id
    , name = GroupDoc.getGroupDocName groupDoc
    , isArchived = GroupDoc.isGroupDocArchived groupDoc
    , mode = GDFM_Edit
    }


createAddGroupDocForm : GroupDocType -> GroupDocForm
createAddGroupDocForm groupDocType =
    let
        id =
            ""
    in
    { id = id
    , name = ""
    , groupDocType = groupDocType
    , groupDocId = GroupDocId groupDocType id
    , isArchived = False
    , mode = GDFM_Add
    }


setName name model =
    { model | name = name }


createEditContextForm =
    createEditGroupDocForm ContextGroupDocType


createEditProjectForm =
    createEditGroupDocForm ProjectGroupDocType
