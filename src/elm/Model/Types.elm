module Model.Types exposing (..)

import Context
import Ext.Keyboard as Keyboard
import PouchDB
import Project
import Project
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo


type alias EditTodoModel =
    { todoId : Todo.Id
    , todo : Todo.Model
    , todoText : Todo.Text
    , projectName : Project.Name
    , contextName : Context.Name
    }


type alias NewTodoEditModel =
    Todo.Text


type EditMode
    = NewTodoEditMode NewTodoEditModel
    | EditTodo EditTodoModel
    | NotEditing
    | SwitchViewCommandMode
    | SwitchToGroupedViewCommandMode


type alias Selection =
    Set Todo.Id


type MainViewType
    = GroupByContextView
    | ProjectView Project.Id
    | DoneView
    | BinView
    | ProjectListView
    | ContextView Context.Id


type alias Model =
    { now : Time
    , todoStore : Todo.Store
    , projectStore : Project.Store
    , contextStore : Context.Store
    , editModel : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , maybeRunningTodo : Maybe RunningTodo
    , keyboardState : Keyboard.State
    , selection : Selection
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model
