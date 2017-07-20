module GroupDoc.Form exposing (..)

import Document.Types exposing (..)
import GroupDoc.Types exposing (..)
import GroupDoc.Types exposing (..)


createEditGroupDocForm : GroupDocType -> GroupDoc -> GroupDocForm
createEditGroupDocForm groupDocType groupDoc =
    let
        id =
            getDocId groupDoc
    in
        { id = id
        , groupDocType = groupDocType
        , groupDocId = createGroupDocIdFromType groupDocType id
        , name = getGroupDocName groupDoc
        , isArchived = isGroupDocArchived groupDoc
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
        , groupDocId = createGroupDocIdFromType groupDocType id
        , isArchived = False
        , mode = GDFM_Add
        }


setName name model =
    { model | name = name }


createEditContextForm =
    createEditGroupDocForm ContextGroupDocType


createEditProjectForm =
    createEditGroupDocForm ProjectGroupDocType
