module Model.Types exposing (..)

import Project exposing (ProjectList, ProjectName)
import Random.Pcg exposing (Seed)
import RunningTodoDetails exposing (RunningTodoDetails)
import Todo exposing (Todo, TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Time exposing (Time)


type MainViewType
    = AllByGroupView
    | GroupView TodoGroup
    | DoneView
    | BinView
    | ProjectsView


defaultViewType =
    AllByGroupView


type alias EditTodoModel =
    { todo : Todo, todoText : String, projectName : ProjectName }


type EditMode
    = NewTodo String
    | EditTodo EditTodoModel
    | None


type alias Model =
    { now : Time
    , todoList : TodoList
    , editMode : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , runningTodoDetails : Maybe RunningTodoDetails
    , projectList : ProjectList
    }


type alias ModelF =
    Model -> Model
