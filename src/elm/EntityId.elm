module EntityId exposing (..)

import Document.Types exposing (getDocId)
import Entity.Types exposing (EntityId(..))
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import X.Function exposing (..)
import X.Function.Infix exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe


fromTodoDocId =
    TodoId


fromTodo =
    getDocId >> TodoId


fromProjectDocId =
    ProjectId


fromContextDocId =
    ContextId
