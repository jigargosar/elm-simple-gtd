module Model.Types exposing (..)

import EditModel.Types exposing (..)
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




type alias Model =
    { now : Time
    , todoList : TodoList
    , editModel : EditModel
    , mainViewType : MainViewType
    , seed : Seed
    , runningTodoDetails : Maybe RunningTodoDetails
    , projectList : ProjectList
    }


type alias ModelF =
    Model -> Model

