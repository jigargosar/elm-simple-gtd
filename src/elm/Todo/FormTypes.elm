module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import Menu
import Menu.Types exposing (MenuState)
import Time exposing (Time)


type alias TodoFormCommon a =
    { a
        | text : String
        , menuState : MenuState
        , date : String
        , time : String
        , maybeComputedTime : Maybe Time
        , mode : TodoFormMode
    }


type TodoFormMode
    = TFM_Edit EditTodoFormMode
    | TFM_Add AddTodoFormMode


type alias AddTodoForm =
    TodoFormCommon
        { atfMode : AddTodoFormMode
        }


type AddTodoFormMode
    = ATFM_AddWithFocusInEntityAsReference
    | ATFM_AddToInbox
    | ATFM_SetupFirstTodo


type EditTodoFormMode
    = ETFM_EditTodoText
    | ETFM_EditTodoReminder
    | ETFM_EditTodoContext
    | ETFM_XMEditTodoProject


type alias EditTodoForm =
    TodoFormCommon
        { id : DocId
        , entity : Entity
        , todoId : DocId
        , contextId : DocId
        , projectId : DocId
        , etfMode : EditTodoFormMode
        }


type EditTodoFormAction
    = SetTodoText String
    | SetTodoMenuState Menu.State
    | SetTodoReminderDate String
    | SetTodoReminderTime String


type TodoExclusiveMode
    = TXM_EditTodoForm EditTodoForm
    | TXM_AddTodoForm AddTodoForm
