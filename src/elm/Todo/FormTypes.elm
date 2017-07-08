module Todo.FormTypes exposing (..)

import Document.Types exposing (DocId)
import Entity.Types exposing (EntityType)
import Todo.Types exposing (TodoText)


type alias TodoEditForm =
    { id : DocId
    , todoText : TodoText
    , entity : EntityType
    }
