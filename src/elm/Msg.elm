module Msg exposing (..)

import Dom
import EditModel.Types exposing (..)
import Ext.Cmd
import Ext.Keyboard exposing (KeyboardEvent)
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


saveNewTodo =
    Create


start =
    Start


stop =
    Stop


startAddingTodo =
    AddTodoClicked


onNewTodoInput =
    NewTodoTextChanged


onNewTodoBlur =
    NewTodoBlur


onNewTodoKeyUp =
    NewTodoKeyUp


onEditTodoKeyUp =
    EditTodoKeyUp


stopAndMarkDone =
    MarkRunningTodoDone


type Msg
    = NoOp
    | Start TodoId
    | Stop
    | MarkRunningTodoDone
    | ToggleTodoDone TodoId
    | ToggleTodoDeleted TodoId
    | SetTodoContext TodoContext TodoId
    | SetTodoText String TodoId
    | Create String
    | AddTodoClicked
    | NewTodoTextChanged TodoText
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | FocusPaperInput String
    | EditTodoTextChanged String
    | EditTodoProjectNameChanged ProjectName
    | EditTodoKeyUp KeyboardEvent
    | SetMainViewType MainViewType
    | OnNowChanged Time
    | OnMsgList (List Msg)


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
