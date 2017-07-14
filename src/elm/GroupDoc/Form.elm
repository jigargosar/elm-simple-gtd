module GroupDoc.Form exposing (..)

import Document.Types exposing (..)
import GroupDoc.FormTypes exposing (..)
import GroupDoc.Types exposing (..)


init : GroupDocType -> GroupDoc -> GroupDocForm
init groupDocType groupDoc =
    { id = getDocId groupDoc
    , name = getGroupDocName groupDoc
    , groupDocType = groupDocType
    , isArchived = isGroupDocArchived groupDoc
    }


setName name model =
    { model | name = name }


createEditContextForm =
    init ContextGroupDoc


createEditProjectForm =
    init ProjectGroupDoc
