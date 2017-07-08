module Todo.Form exposing (..)

import Document
import Document.Types exposing (DocId)
import Entity
import Entity.Types exposing (EntityType)
import Todo
import Todo.FormTypes exposing (TodoEditForm)
import Todo.Types exposing (TodoDoc)


type Action
    = SetText String


create : TodoDoc -> TodoEditForm
create todo =
    { id = Document.getId todo
    , todoText = Todo.getText todo
    , entity = Entity.Types.TodoEntity todo
    }


set : Action -> TodoEditForm -> TodoEditForm
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
