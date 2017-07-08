module GroupDoc.EditForm exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (EntityType, createContextEntity, createProjectEntity)
import GroupDoc.FormTypes exposing (GroupDocEditModel, NameInputLabel)
import GroupDoc.Types exposing (GroupDoc, getGroupDocName, isGroupDocArchived)


init : (GroupDoc -> EntityType) -> NameInputLabel -> GroupDoc -> GroupDocEditModel
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
