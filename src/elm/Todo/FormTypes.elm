module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (EntityType)
import Menu.Types exposing (MenuState)
import Todo.Types exposing (TodoDoc, TodoText)


type alias TodoEditForm =
    { id : DocId
    , todoText : TodoText
    , entity : EntityType
    }


type alias TodoGroupFrom =
    { todo : TodoDoc
    , todoId : DocId
    , contextId : DocId
    , projectId : DocId
    , menuState : MenuState
    }
