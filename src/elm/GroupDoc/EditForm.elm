module GroupDoc.EditForm exposing (..)

import Document
import Entity
import GroupDoc
import GroupDoc.Types
import Types


type alias NameLabel =
    String


type alias Model =
    { id : Types.DocId
    , name : GroupDoc.Types.Name
    , entity : Entity.Entity
    , isArchived : Bool
    , nameLabel : NameLabel
    }


init : (GroupDoc.Types.Model -> Entity.Entity) -> NameLabel -> GroupDoc.Types.Model -> Model
init toEntity nameLabel groupDoc =
    { id = Document.getId groupDoc
    , name = GroupDoc.getName groupDoc
    , entity = toEntity groupDoc
    , isArchived = GroupDoc.isArchived groupDoc
    , nameLabel = nameLabel
    }


setName name model =
    { model | name = name }


forContext =
    init Entity.fromContext "Context Name"


forProject =
    init Entity.fromProject "Project Name"
