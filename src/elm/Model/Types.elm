module Model.Types exposing (..)

import Context
import Ext.Keyboard as Keyboard
import PouchDB
import Project exposing (ProjectId, ProjectName)
import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import Set exposing (Set)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo


type alias TodoStore =
    PouchDB.Store Todo.OtherFields


type alias EditTodoModel =
    { todoId : Todo.Id
    , todo : Todo.Model
    , todoText : Todo.Text
    , projectName : Project.ProjectName
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
    | ProjectView ProjectId
    | DoneView
    | BinView
    | ProjectListView
    | ContextView Context.Id


type alias Model =
    { now : Time
    , todoStore : TodoStore
    , projectStore : ProjectStore
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
