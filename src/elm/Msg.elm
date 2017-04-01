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
import Todo exposing (Todo, TodoGroup, TodoId, TodoList, TodoText)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Types exposing (..)


type UpdateAction
    = ToggleDoneUA
    | MarkDoneUA
    | SetGroupUA TodoGroup
    | SetTextUA String
    | ToggleDeleteUA
    | UpdateModifiedAtUA


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
    | SetGroup TodoGroup TodoId
    | SetText String TodoId
    | ToggleDelete TodoId
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
    | UpdateTodoFields (List TodoField) Todo


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
