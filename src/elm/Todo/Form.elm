module Todo.Form exposing (..)

import Document
import Document.Types exposing (getDocId)
import Entity.Types exposing (Entity(TodoEntity))
import Menu
import Todo
import Todo.FormTypes exposing (EditTodoFormAction(..), TodoEditForm)
import Todo.Types exposing (TodoDoc, getTodoText)


create : TodoDoc -> TodoEditForm
create todo =
    { id = Document.getId todo
    , todoText = getTodoText todo
    , entity = TodoEntity todo
    , todoId = getDocId todo
    , contextId = Todo.getContextId todo
    , projectId = Todo.getProjectId todo
    , menuState = Menu.initState
    }


setMenuState menuState form =
    { form | menuState = menuState }


set : EditTodoFormAction -> TodoEditForm -> TodoEditForm
set action model =
    case action of
        SetTodoText value ->
            { model | todoText = value }

        SetTodoMenuState state ->
            setMenuState state model
