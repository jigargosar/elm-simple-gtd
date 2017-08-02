module EntityId exposing (..)

import Document
import Entity exposing (..)


fromTodoDocId =
    TodoId


fromTodo =
    Document.getId >> TodoId


fromProjectDocId =
    ProjectId


fromContextDocId =
    ContextId
