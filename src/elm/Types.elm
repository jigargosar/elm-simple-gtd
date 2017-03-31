module Types exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Project exposing (Project, ProjectList, ProjectName)


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
    = EditNewTodoMode String
    | EditTodoMode EditTodoModel
    | NotEditing


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


type TodoField
    = TodoText String
    | TodoProject Project
