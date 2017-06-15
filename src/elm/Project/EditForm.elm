module Project.EditForm exposing (..)

import Document
import Entity
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Project


type alias Model =
    { id : Document.Id
    , name : Project.Name
    , entity : Entity.Entity
    }


init : Project.Model -> Model
init project =
    { id = Document.getId project
    , name = Project.getName project
    , entity = Entity.ProjectEntity project
    }


setName name model =
    { model | name = name }
