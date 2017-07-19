module GroupDoc.Form exposing (..)

import Document.Types exposing (..)
import GroupDoc.FormTypes exposing (..)
import GroupDoc.Types exposing (..)


createEditGroupDocForm : GroupDocType -> GroupDoc -> GroupDocForm
createEditGroupDocForm groupDocType groupDoc =
    { id = getDocId groupDoc
    , name = getGroupDocName groupDoc
    , groupDocType = groupDocType
    , isArchived = isGroupDocArchived groupDoc
    , mode = GDFM_Edit
    }


createAddGroupDocForm : GroupDocType -> GroupDocForm
createAddGroupDocForm groupDocType =
    { id = ""
    , name = "<Name>"
    , groupDocType = groupDocType
    , isArchived = False
    , mode = GDFM_Add
    }


setName name model =
    { model | name = name }


createEditContextForm =
    createEditGroupDocForm ContextGroupDocType


createEditProjectForm =
    createEditGroupDocForm ProjectGroupDocType
