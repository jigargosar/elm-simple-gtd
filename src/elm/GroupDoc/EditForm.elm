module GroupDoc.EditForm exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity, createContextEntity, createProjectEntity)
import GroupDoc.FormTypes exposing (GroupDocEditForm, NameInputLabel)
import GroupDoc.Types exposing (GroupDoc, getGroupDocName, isGroupDocArchived)


init : (GroupDoc -> Entity) -> NameInputLabel -> GroupDoc -> GroupDocEditForm
init toEntity nameLabel groupDoc =
    { id = getDocId groupDoc
    , name = getGroupDocName groupDoc
    , entity = toEntity groupDoc
    , isArchived = isGroupDocArchived groupDoc
    , nameLabel = nameLabel
    }


setName name model =
    { model | name = name }


forContext =
    init createContextEntity "Context Name"


forProject =
    init createProjectEntity "Project Name"
