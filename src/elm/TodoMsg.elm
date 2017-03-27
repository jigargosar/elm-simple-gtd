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


type NowAction
    = UpdateTodo UpdateAction TodoId
    | CreateNewTodo String
    | SplitNewTodoFrom Todo


type TodoMsg
    = CreateNewTodoOld String
    | SplitNewTodoFromOld Todo
    | Start TodoId
    | Stop
    | StopAndMarkDone
    | OnRequiresNowAction NowAction
    | OnNowAction NowAction Time


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
    CreateNewTodoOld


splitNewTodoFrom =
    SplitNewTodoFromOld


start =
    Start


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
