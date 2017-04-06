module Model.Types exposing (..)

import Ext.Keyboard as Keyboard
import PouchDB
import Project exposing (ProjectId, ProjectName)
import ProjectStore.Types exposing (ProjectStore)
import Random.Pcg exposing (Seed)
import RunningTodo exposing (RunningTodo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Time exposing (Time)
import Todo.Types exposing (..)


type alias TodoStore =
    PouchDB.Store Todo.Types.OtherFields


type alias EditTodoModel =
    { todoId : TodoId, todo : Todo, todoText : TodoText, projectName : Project.ProjectName }


type alias NewTodoModel =
    TodoText


type EditMode
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | NotEditing


type alias Selection =
    List TodoId


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
    , editModel : EditMode
    , mainViewType : MainViewType
    , seed : Seed
    , maybeRunningTodo : Maybe RunningTodo
    , projectStore : ProjectStore
    , keyboardState : Keyboard.State
    , selection : Selection
    }


type ModelField
    = NowField Time
    | MainViewTypeField MainViewType


type alias ModelF =
    Model -> Model
