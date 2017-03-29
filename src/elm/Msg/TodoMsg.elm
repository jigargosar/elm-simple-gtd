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
    | Create String
    | CopyAndEdit Todo


type TodoMsg
    = Start TodoId
    | Stop
    | MarkRunningTodoDone
    | OnRequiresNowAction RequiresNowAction
    | OnActionWithNow RequiresNowAction Time
    | ToggleDone TodoId


update =
    Update >>> OnRequiresNowAction


toggleDone =
    update ToggleDoneUA


markDone =
    update MarkDoneUA


toggleDelete =
    update ToggleDeleteUA


setGroup group =
    update (SetGroupUA group)


setText text =
    update (SetTextUA text)


saveNewTodo =
    Create >> OnRequiresNowAction


splitNewTodoFrom =
    CopyAndEdit >> OnRequiresNowAction


start =
    Start


stop =
    Stop


markRunningTodoDone =
    MarkRunningTodoDone
