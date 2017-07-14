module GroupDoc.EditForm exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity, createContextEntity, createProjectEntity)
import GroupDoc.FormTypes exposing (GroupDocEditForm, NameInputLabel)
import GroupDoc.Types exposing (GroupDoc, GroupDocType(..), getGroupDocName, isGroupDocArchived)


init : GroupDocType -> NameInputLabel -> GroupDoc -> GroupDocEditForm
init groupDocType nameLabel groupDoc =
    { id = getDocId groupDoc
    , name = getGroupDocName groupDoc
    , groupDocType = groupDocType
    , isArchived = isGroupDocArchived groupDoc
    , nameLabel = nameLabel
    }


setName name model =
    { model | name = name }


createEditContextForm =
    init ContextGroupDoc "Context Name"


createEditProjectForm =
    init ProjectGroupDoc "Project Name"
