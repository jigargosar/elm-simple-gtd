module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (Entity)
import Menu.Types exposing (MenuState)
import Todo.Types exposing (TodoDoc, TodoText)


type alias TodoEditForm =
    { id : DocId
    , todoText : TodoText
    , entity : Entity
    }


type alias TodoGroupFrom =
    { todoId : DocId
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
    = SetDate String
    | SetTime String


type EditTodoFormAction
    = SetText String
