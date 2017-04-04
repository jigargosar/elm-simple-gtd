module Model.Types exposing (..)

import EditModel.Types exposing (..)
import Project exposing (ProjectName)
import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import TodoList.Types exposing (..)
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
    | None


type MainViewType
    = AllByTodoContextView
    | TodoContextView TodoContext
    | DoneView
    | BinView
    | ProjectsView


type alias Model =
    { now : Time
    , todoList : TodoList
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
