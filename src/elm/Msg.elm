module Msg exposing (..)

import Context
import Dom
import EditMode exposing (EditTodoModel)
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Model.Types exposing (..)
import PouchDB
import Project
import Return
import RunningTodo exposing (RunningTodo)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
import Types exposing (..)


setTodoContext =
    SetTodoContext


start =
    Start


stop =
    Stop


onNewTodoInput =
    NewTodoTextChanged


stopAndMarkDone =
    MarkRunningTodoDone


type Msg
    = NoOp
    | Start Todo.Model
    | Stop
    | MarkRunningTodoDone
    | ToggleTodoDone Todo.Model
    | ToggleTodoDeleted Todo.Model
    | SetTodoContext Context.Model Todo.Model
    | CreateTodo String
    | CopyAndEditTodo Todo.Model
    | StartAddingTodo
    | NewTodoTextChanged Todo.Text
    | DeactivateEditingMode
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo.Model
    | FocusPaperInput String
    | EditTodoTextChanged EditTodoModel String
    | EditTodoProjectNameChanged EditTodoModel Project.Name
    | EditTodoContextNameChanged EditTodoModel Context.Name
    | EditTodoKeyUp EditTodoModel KeyboardEvent
    | TodoCheckBoxClicked Todo.Model
    | ClearSelection
    | SelectionDoneClicked
    | SelectionEditClicked
    | SelectionTrashClicked
    | SetView MainViewType
    | OnNowChanged Time
    | OnMsgList (List Msg)
    | OnKeyboardMsg Keyboard.Msg
    | OnKeyUp Keyboard.Key
    | OnEntityAction EntityId Entity EntityAction
    | OnSettingsClicked Entity


toCmds : List Msg -> Cmd Msg
toCmds =
    Ext.Cmd.toCmds OnMsgList


toCmd : msg -> Cmd msg
toCmd =
    Ext.Cmd.toCmd


type alias Return =
    Return.Return Msg Model


type alias ReturnTuple a =
    Return.Return Msg ( a, Model )


type alias ReturnF =
    Return -> Return
