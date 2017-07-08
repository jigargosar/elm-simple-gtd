module Todo.Form exposing (..)

import Document
import Document.Types exposing (DocId)
import Entity
import Entity.Types exposing (EntityType(TodoEntity))
import Todo.FormTypes exposing (TodoAction(SetText), TodoEditForm)
import Todo.Types exposing (TodoDoc, getTodoText)


create : TodoDoc -> TodoEditForm
create todo =
    { id = Document.getId todo
    , todoText = getTodoText todo
    , entity = TodoEntity todo
    }


set : TodoAction -> TodoEditForm -> TodoEditForm
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
