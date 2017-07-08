module Todo.Form exposing (..)

import Document
import Entity
import Entity.Types
import Todo
import Todo.Types exposing (TodoDoc)
import Types


type alias Model =
    { id : Types.DocId__
    , todoText : Todo.Text
    , entity : Entity.Entity
    }


type Action
    = SetText String


create : TodoDoc -> Model
create todo =
    { id = Document.getId todo
    , todoText = Todo.getText todo
    , entity = Entity.Types.TodoEntity todo
    }


set : Action -> Model -> Model
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
