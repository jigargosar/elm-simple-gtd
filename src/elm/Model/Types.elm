module Model.Types exposing (..)

import EditModel.Types exposing (..)
import Project exposing (ProjectList, ProjectName)
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import TodoList.Types exposing (..)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Time exposing (Time)
import Todo.Types exposing (..)


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
    , projectList : ProjectList
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model
