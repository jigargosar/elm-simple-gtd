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
    = Start TodoId
    | Stop
    | MarkRunningTodoDone
    | OnRequiresNowAction RequiresNowAction
    | OnActionWithNow RequiresNowAction Time
    | ToggleDone TodoId
    | MarkDone TodoId
    | SetGroup TodoGroup TodoId
    | SetText String TodoId
    | ToggleDelete TodoId


markDone =
    MarkDone


toggleDelete =
    ToggleDelete


setGroup =
    SetGroup


setText =
    SetText


saveNewTodo =
    CreateA >> OnRequiresNowAction


splitNewTodoFrom =
    CopyAndEditA >> OnRequiresNowAction


start =
    Start


stop =
    Stop


markRunningTodoDone =
    MarkRunningTodoDone
