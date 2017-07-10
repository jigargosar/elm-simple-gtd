module Todo.Form exposing (..)

import Document
import Entity.Types exposing (Entity(TodoEntity))
import Todo.FormTypes exposing (EditTodoFormAction(SetText), TodoEditForm)
import Todo.Types exposing (TodoDoc, getTodoText)


create : TodoDoc -> TodoEditForm
create todo =
    { id = Document.getId todo
    , todoText = getTodoText todo
    , entity = TodoEntity todo
    }


set : EditTodoFormAction -> TodoEditForm -> TodoEditForm
set action model =
    case action of
        SetText value ->
            { model | todoText = value }
