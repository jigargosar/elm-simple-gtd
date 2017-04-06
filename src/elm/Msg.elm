module Msg exposing (..)

import Dom
import Ext.Cmd
import Ext.Keyboard as Keyboard exposing (KeyboardEvent)
import Model.Types exposing (..)
import Project exposing (ProjectName)
import Return
import RunningTodo exposing (RunningTodo)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo.Types exposing (..)
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
    | Start Todo
    | Stop
    | MarkRunningTodoDone
    | ToggleTodoDone Todo
    | ToggleTodoDeleted Todo
    | SetTodoContext TodoContext Todo
    | Create String
    | StartAddingTodo
    | NewTodoTextChanged TodoText
    | DeactivateEditingMode
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | FocusPaperInput String
    | EditTodoTextChanged EditTodoModel String
    | EditTodoProjectNameChanged EditTodoModel ProjectName
    | EditTodoKeyUp EditTodoModel KeyboardEvent
    | SetMainViewType MainViewType
    | OnNowChanged Time
    | OnMsgList (List Msg)
    | OnKeyboardMsg Keyboard.Msg
    | OnKeyUp Keyboard.Key


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
