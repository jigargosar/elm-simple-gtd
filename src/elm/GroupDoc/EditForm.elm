module GroupDoc.EditForm exposing (..)

import Document.Types exposing (DocId, getDocId)
import Entity.Types exposing (EntityType, createContextEntity, createProjectEntity)
import GroupDoc.Types exposing (GroupDoc, GroupDocName, getGroupDocName, isGroupDocArchived)


type alias NameInputLabel =
    String


type alias Model =
    { id : DocId
    , name : GroupDocName
    , entity : EntityType
    , isArchived : Bool
    , nameLabel : NameInputLabel
    }


init : (GroupDoc -> EntityType) -> NameInputLabel -> GroupDoc -> Model
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
