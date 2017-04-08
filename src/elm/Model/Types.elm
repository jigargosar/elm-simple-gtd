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
import Todo.Types exposing (..)


type alias TodoStore =
    PouchDB.Store Todo.Types.OtherFields


type alias EditTodoModel =
    { todoId : TodoId
    , todo : Todo
    , todoText : TodoText
    , projectName : Project.ProjectName
    , contextName : Context.Name
    }


type alias NewTodoEditModel =
    TodoText


type EditMode
    = NewTodoEditMode NewTodoEditModel
    | EditTodo EditTodoModel
    | NotEditing
    | SwitchViewCommandMode
    | SwitchToGroupedViewCommandMode


type alias Selection =
    Set TodoId


type MainViewType
    = GroupByContextView
    | TodoContextView String
    | ProjectView ProjectId
    | DoneView
    | BinView
    | ProjectListView


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
