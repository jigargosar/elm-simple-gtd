module Todo.Types exposing (..)

import Context
import PouchDB
import Project exposing (ProjectId)
import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Pipeline as D
import Json.Encode as E


type alias TodoId =
    String


type alias TodoText =
    String


type alias TodoRecord =
    { done : Bool
    , text : TodoText
    , dueAt : Maybe Time
    , deleted : Bool
    , projectId : Maybe ProjectId
    , contextId : Maybe Context.Id
    }


type alias OtherFields =
    PouchDB.HasTimeStamps TodoRecord


type alias Todo =
    PouchDB.Document OtherFields


type alias ViewModel =
    Todo


type alias EncodedTodo =
    E.Value


type TodoUpdateAction
    = SetDone Bool
    | SetText TodoText
    | SetDeleted Bool
    | SetContextId (Maybe Context.Id)
    | SetContext (Maybe Context.Model)
    | SetProjectId (Maybe ProjectId)
    | SetProject (Maybe Project.Project)
    | ToggleDone
    | ToggleDeleted
