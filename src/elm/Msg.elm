module Msg exposing (..)

import Ext.Cmd
import KeyboardExtra exposing (KeyboardEvent)
import Return
import RunningTodoDetails exposing (RunningTodoDetails)
import Random.Pcg exposing (Seed)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Types exposing (MainViewType, Model)


type UpdateAction
    = ToggleDoneUA
    | MarkDoneUA
    | SetGroupUA TodoGroup
    | SetTextUA String
    | ToggleDeleteUA


type RequiresNowAction
    = Update UpdateAction TodoId
    | CreateA String
    | CopyAndEditA Todo


markDone =
    MarkDone


toggleDelete =
    ToggleDelete


setGroup =
    SetGroup


setText =
    SetText


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




onEditTodoInput =
    EditTodoTextChanged


onEditTodoBlur =
    EditTodoBlur


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
    | SetGroup TodoGroup TodoId
    | SetText String TodoId
    | ToggleDelete TodoId
    | Create String
    | CopyAndEdit Todo
    | AddTodoClicked
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent
    | StartEditingTodo Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent
    | SetMainViewType MainViewType
    | OnUpdateNow Time
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
