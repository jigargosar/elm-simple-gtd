module Todo.FormTypes exposing (..)

import Document exposing (DocId)
import Menu
import Menu.Types exposing (MenuState)
import Time exposing (Time)


type alias TodoForm =
    { id : DocId
    , contextId : DocId
    , projectId : DocId
    , text : String
    , menuState : MenuState
    , date : String
    , time : String
    , maybeComputedTime : Maybe Time
    , mode : TodoFormMode
    }


type TodoFormMode
    = TFM_Edit EditTodoFormMode
    | TFM_Add AddTodoFormMode


type AddTodoFormMode
    = ATFM_AddWithFocusInEntityAsReference
    | ATFM_AddToInbox
    | ATFM_SetupFirstTodo


type EditTodoFormMode
    = ETFM_EditTodoText
    | ETFM_EditTodoSchedule
    | ETFM_EditTodoContext
    | ETFM_EditTodoProject


type TodoFormAction
    = SetTodoText String
    | SetTodoMenuState Menu.State
    | SetTodoReminderDate String
    | SetTodoReminderTime String
