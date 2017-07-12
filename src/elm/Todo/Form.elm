module Todo.Form exposing (..)

import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(TodoEntity))
import Menu
import Todo
import Todo.FormTypes exposing (EditTodoFormAction(..), TodoEditForm)
import Todo.Types exposing (TodoDoc, getTodoText)
import X.Record exposing (field, set)


create : TodoDoc -> TodoEditForm
create todo =
    { id = Document.getId todo
    , name = getTodoText todo
    , entity = TodoEntity todo
    , todoId = getDocId todo
    , contextId = Todo.getContextId todo
    , projectId = Todo.getProjectId todo
    , menuState = Menu.initState
    }


name =
    field .name (\s b -> { b | name = s })


menuState =
    field .menuState (\s b -> { b | menuState = s })


setMenuState menuState form =
    { form | menuState = menuState }


update : EditTodoFormAction -> TodoEditForm -> TodoEditForm
update action =
    case action of
        SetTodoText value ->
            set name value

        SetTodoMenuState value ->
            set menuState value
