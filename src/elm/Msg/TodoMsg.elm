module Msg.TodoMsg exposing (..)

import KeyboardExtra exposing (KeyboardEvent)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


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


type TodoMsg
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
