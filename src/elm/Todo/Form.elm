module Todo.Form exposing (..)

import Document
import Entity
import Entity.Types
import Todo
import Types


type alias Model =
    { id : Types.DocId
    , todoText : Todo.Text
    , entity : Entity.Entity
    }


type Action
    = SetText String


create : Todo.Model -> Model
create todo =
    { id = Document.getId todo
    , todoText = Todo.getText todo
    , entity = Entity.Types.Todo todo
    }


set : Action -> Model -> Model
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
