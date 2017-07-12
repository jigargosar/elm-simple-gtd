module Todo.Form exposing (..)

import Document
import Document.Types exposing (DocId, getDocId)
import Entity.Types exposing (Entity(TodoEntity))
import Menu
import Menu.Types exposing (MenuState)
import Todo
import Todo.Types exposing (TodoDoc, TodoText, getTodoText)
import X.Record exposing (field, set)


type alias TodoEditForm =
    { id : DocId
    , name : TodoText
    , entity : Entity
    , todoId : DocId
    , contextId : DocId
    , projectId : DocId
    , menuState : MenuState
    }


type alias TodoMoreMenuForm =
    { todoId : DocId
    , menuState : MenuState
    }


type alias AddTodoForm =
    { text : TodoText
    , referenceEntity : Entity
    }


type alias EditTodoReminderForm =
    { id : DocId
    , date : String
    , time : String
    }


type EditTodoReminderFormAction
    = SetTodoReminderDate String
    | SetTodoReminderTime String


type EditTodoFormAction
    = SetTodoText String
    | SetTodoMenuState Menu.State


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


update : EditTodoFormAction -> TodoEditForm -> TodoEditForm
update action =
    case action of
        SetTodoText value ->
            set name value

        SetTodoMenuState value ->
            set menuState value


f =
    1
