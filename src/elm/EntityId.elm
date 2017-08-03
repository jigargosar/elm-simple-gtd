module EntityId exposing (..)

import Document
import Entity exposing (..)


fromTodo =
    Document.getId >> createTodoEntityId


fromContext =
    Document.getId >> createContextEntityId


fromProjectDocId =
    ProjectEntityId


fromContextDocId =
    ContextEntityId


fromTodoDocId =
    TodoEntityId
