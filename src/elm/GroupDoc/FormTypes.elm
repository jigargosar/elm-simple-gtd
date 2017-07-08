module GroupDoc.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (EntityType)
import GroupDoc.Types exposing (GroupDocName)


type alias NameInputLabel =
    String


type alias GroupDocEditForm =
    { id : DocId
    , name : GroupDocName
    , entity : EntityType
    , isArchived : Bool
    , nameLabel : NameInputLabel
    }
