module Context.EditForm exposing (..)

import Document
import Entity
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Context


type alias Model =
    { id : Document.Id
    , name : Context.Name
    , entity : Entity.Entity
    }


init : Context.Model -> Model
init context =
    { id = Document.getId context
    , name = Context.getName context
    , entity = Entity.ContextEntity context
    }


setName name model =
    { model | name = name }
