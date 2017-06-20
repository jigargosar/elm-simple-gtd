module GroupDoc.EditForm exposing (..)

import Document
import Entity
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Context
import GroupDoc


type alias NameLabel =
    String


type alias Model =
    { id : Document.Id
    , name : GroupDoc.Name
    , entity : Entity.Entity
    , isArchived : Bool
    , nameLabel : NameLabel
    }


init : (GroupDoc.Model -> Entity.Entity) -> NameLabel -> GroupDoc.Model -> Model
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
    init Entity.Context "Context Name"


forProject =
    init Entity.Project "Project Name"
