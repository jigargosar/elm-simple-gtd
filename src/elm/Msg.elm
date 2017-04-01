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
import TodoModel.Types exposing (..)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Types exposing (..)


type UpdateAction
    = ToggleDoneUA
    | MarkDoneUA
    | SetTodoContextUA TodoContext
    | SetTextUA String
    | ToggleDeleteUA
    | UpdateModifiedAtUA


type RequiresNowAction
    = Update UpdateAction TodoId
    | CreateA String
    | CopyAndEditA TodoModel


markDone =
    MarkDone


toggleDelete =
    ToggleDelete


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


toggleDone =
    ToggleDone


stopAndMarkDone =
    MarkRunningTodoDone


type Msg
    = NoOp
    | Start TodoId
    | Stop
    | MarkRunningTodoDone
    | OnActionWithNow RequiresNowAction Time
    | ToggleDone TodoId
    | MarkDone TodoId
    | SetTodoContext TodoContext TodoId
    | SetText String TodoId
    | ToggleDelete TodoId
    | Create String
    | CopyAndEdit TodoModel
    | AddTodoClicked
    | NewTodoTextChanged TodoText
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo TodoModel
    | FocusPaperInput String
    | EditTodoTextChanged EditTodoModel String
    | EditTodoProjectNameChanged EditTodoModel ProjectName
    | EditTodoKeyUp TodoModel KeyboardEvent
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


type alias ReturnF =
    Return -> Return
