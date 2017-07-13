module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import Menu
import Menu.Types exposing (MenuState)
import Time exposing (Time)
import Todo.Types exposing (TodoDoc, TodoText)


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


type alias TodoFormUpdateFields a =
    { a
        | text : String
        , menuState : MenuState
        , date : String
        , time : String
        , maybeComputedTime : Maybe Time
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


type EditTodoFormAction
    = SetTodoText String
    | SetTodoMenuState Menu.State
    | SetTodoReminderDate String
    | SetTodoReminderTime String


type AddTodoFormMode
    = NTFM_NewTodo
    | NTFM_SetupFirstTodo


type TodoForm
    = TFT_Edit EditTodoForm
    | TFT_NONE



--        | NewTodoFormType NewTodoFormMode
