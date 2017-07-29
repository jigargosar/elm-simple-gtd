module EntityId exposing (..)

import Document
import Entity.Types exposing (..)


fromTodoDocId =
    TodoId


fromTodo =
    Document.getId >> TodoId


fromProjectDocId =
    ProjectId


fromContextDocId =
    ContextId
