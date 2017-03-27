module TodoMsg exposing (..)

import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


type UpdateAction
    = ToggleDone
    | MarkDone
    | SetGroup TodoGroup
    | SetText String
    | ToggleDelete



--    | CopyAndStartEdit


type CreateAction
    = FromText String
    | FromId TodoId



--type ActiveTaskAction = Start TodoId | Stop | MarkDone


type RequiresNowAction
    = UpdateTodo UpdateAction TodoId
    | CreateNewTodo String
    | SplitNewTodoFrom Todo


type TodoMsg
    = Start TodoId
    | Stop
    | StopAndMarkDone
    | OnRequiresNowAction RequiresNowAction
    | OnActionWithNow RequiresNowAction Time


updateTodo =
    UpdateTodo >>> OnRequiresNowAction


toggleDone =
    updateTodo ToggleDone


markDone =
    updateTodo MarkDone


toggleDelete =
    updateTodo ToggleDelete


setGroup group =
    updateTodo (SetGroup group)


setText text =
    updateTodo (SetText text)


saveNewTodo =
    CreateNewTodo >> OnRequiresNowAction


splitNewTodoFrom =
    SplitNewTodoFrom >> OnRequiresNowAction


start =
    Start


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
