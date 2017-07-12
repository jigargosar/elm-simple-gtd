module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import Menu
import Menu.Types exposing (MenuState)
import Todo.Types exposing (TodoDoc, TodoText)


type alias EditTodoForm =
    { id : DocId
    , name : TodoText
    , entity : Entity
    , todoId : DocId
    , contextId : DocId
    , projectId : DocId
    , menuState : MenuState
    , date : String
    , time : String
    , xmType : XMEditTodoType
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


type XMEditTodoType
    = XMEditTodoText
    | XMEditTodoReminder
    | XMEditTodoContext
    | XMEditTodoProject
