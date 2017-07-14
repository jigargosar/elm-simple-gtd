module GroupDoc.Form exposing (..)

import Document.Types exposing (..)
import GroupDoc.FormTypes exposing (..)
import GroupDoc.Types exposing (..)


createEditForm : GroupDocType -> GroupDoc -> GroupDocForm
createEditForm groupDocType groupDoc =
    { id = getDocId groupDoc
    , name = getGroupDocName groupDoc
    , groupDocType = groupDocType
    , isArchived = isGroupDocArchived groupDoc
    , mode = GDFM_Edit
    }


createAddForm : GroupDocType -> GroupDocForm
createAddForm groupDocType =
    { id = ""
    , name = ""
    , groupDocType = groupDocType
    , isArchived = False
    , mode = GDFM_Add
    }


setName name model =
    { model | name = name }


createEditContextForm =
    createEditForm ContextGroupDoc


createEditProjectForm =
    createEditForm ProjectGroupDoc
