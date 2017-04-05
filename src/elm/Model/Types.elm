module Model.Types exposing (..)

import Project exposing (ProjectId, ProjectName)
import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import TodoStore.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo.Types exposing (..)


type alias EditTodoModel =
    { todoId : TodoId, todo : Todo, todoText : TodoText, projectName : Project.ProjectName }


type alias NewTodoModel =
    TodoText


type EditModel
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | NotEditing


type MainViewType
    = AllByTodoContextView
    | TodoContextView String
    | ProjectView ProjectId
    | DoneView
    | BinView
    | ProjectListView


type alias Model =
    { now : Time
    , todoStor : TodoStore
    , editModel : EditModel
    , mainViewType : MainViewType
    , seed : Seed
    , maybeRunningTodo : Maybe RunningTodo
    , projectStore : ProjectStore
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model
