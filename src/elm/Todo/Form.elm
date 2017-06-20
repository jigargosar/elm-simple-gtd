module Todo.Form exposing (..)

import Context
import Document
import Entity
import Project
import Time exposing (Time)
import Time.Format
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Todo


type alias Model =
    { id : Document.Id
    , todoText : Todo.Text
    , entity : Entity.Entity
    }


type Action
    = SetText String


create : Todo.Model -> Model
create todo =
    { id = Document.getId todo
    , todoText = Todo.getText todo
    , entity = Entity.Task todo
    }


set : Action -> Model -> Model
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
