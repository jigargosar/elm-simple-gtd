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


type alias Model =
    { id : Document.Id
    , name : GroupDoc.Name
    , entity : Entity.Entity
    , isArchived : Bool
    }


init : (GroupDoc.Model -> Entity.Entity) -> GroupDoc.Model -> Model
init toEntity groupDoc =
    { id = Document.getId groupDoc
    , name = GroupDoc.getName groupDoc
    , entity = toEntity groupDoc
    , isArchived = GroupDoc.isArchived groupDoc
    }


setName name model =
    { model | name = name }
