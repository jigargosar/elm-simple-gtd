module EntityId exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (EntityId(..))


fromTodoDocId =
    TodoId


fromTodo =
    getDocId >> TodoId


fromProjectDocId =
    ProjectId


fromContextDocId =
    ContextId
