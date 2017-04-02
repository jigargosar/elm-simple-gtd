module Todo.Types exposing (..)

import PouchDB
import Project exposing (ProjectId)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias TodoId =
    String


type alias TodoText =
    String


type TodoContext
    = Session
    | Inbox
    | SomeDayMayBe
    | WaitingFor
    | Project
    | Calender
    | NextAction
    | Reference


type alias TodoRecord =
    { done : Bool
    , text : TodoText
    , dueAt : Maybe Time
    , deleted : Bool
    , context : TodoContext
    , projectId : Maybe ProjectId
    }


type alias Todo =
    PouchDB.Document (PouchDB.WithTimeStamps TodoRecord)


type alias ViewModel =
    Todo


type alias EncodedTodo =
    E.Value


type TodoAction
    = SetTodoDone Bool
    | SetTodoText TodoText
    | SetTodoDeleted Bool
    | SetTodoContext TodoContext
    | SetTodoProjectId (Maybe ProjectId)
    | SetTodoProject (Maybe Project.Project)
