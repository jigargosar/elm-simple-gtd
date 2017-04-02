module Msg exposing (..)

import Dom
import EditModel.Types exposing (..)
import Ext.Cmd
import KeyboardExtra exposing (KeyboardEvent)
import Model.Types exposing (..)
import Project exposing (ProjectName)
import Return
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo.Types exposing (..)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Types exposing (..)


setTodoContext =
    SetTodoContext


saveNewTodo =
    Create


splitNewTodoFrom =
    CopyAndEdit


start =
    Start


stop =
    Stop


markRunningTodoDone =
    MarkRunningTodoDone


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
    | SetTodoDone Bool TodoId
    | ToggleTodoDone TodoId
    | SetTodoContext TodoContext TodoId
    | SetTodoText String TodoId
    | SetTodoDeleted Bool TodoId
    | Create String
    | CopyAndEdit Todo
    | AddTodoClicked
    | NewTodoTextChanged TodoText
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | FocusPaperInput String
    | EditTodoTextChanged EditTodoModel String
    | EditTodoProjectNameChanged EditTodoModel ProjectName
    | EditTodoKeyUp Todo KeyboardEvent
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
