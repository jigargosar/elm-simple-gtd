module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import Menu
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.Types exposing (TodoDoc, TodoText)


type alias TodoFormUpdateFields a =
    { a
        | text : String
        , menuState : MenuState
        , date : String
        , time : String
        , maybeComputedTime : Maybe Time
    }


type alias AddTodoForm =
    TodoFormUpdateFields
        { atfMode : AddTodoFormMode
        }


type EditTodoFormMode
    = ETFM_EditTodoText
    | ETFM_EditTodoReminder
    | ETFM_EditTodoContext
    | ETFM_XMEditTodoProject


type alias EditTodoForm =
    TodoFormUpdateFields
        { id : DocId
        , entity : Entity
        , todoId : DocId
        , contextId : DocId
        , projectId : DocId
        , etfMode : EditTodoFormMode
        }


type alias TodoMoreMenuForm =
    { todoId : DocId
    , menuState : MenuState
    }


type EditTodoFormAction
    = SetTodoText String
    | SetTodoMenuState Menu.State
    | SetTodoReminderDate String
    | SetTodoReminderTime String


type AddTodoFormMode
    = ATFM_AddByFocusInEntity
    | ATFM_AddToInbox
    | ATFM_SetupFirstTodo


type TodoForm
    = TFT_Edit EditTodoForm
    | TFT_NONE
    | TFT_ADD AddTodoFormMode



--        | NewTodoFormType NewTodoFormMode
