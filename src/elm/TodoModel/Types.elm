module TodoModel.Types exposing (..)

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


type alias EncodedTodoList =
    List EncodedTodo


type TodoGroup
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
    , context : TodoGroup
    , projectId : Maybe ProjectId
    }


type alias TodoModel =
    PouchDB.Document (PouchDB.WithTimeStamps TodoRecord)


type alias TodoListModel =
    List TodoModel


type alias EncodedTodo =
    E.Value


type alias ViewModel =
    TodoModel


