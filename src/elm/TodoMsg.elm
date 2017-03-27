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
    | CreateNewTodoRN String
    | SplitNewTodoFromRN Todo


type TodoMsg
    =

    CreateNewTodo String
    | CreateNewTodoAt String Time
    | SplitNewTodoFrom Todo
    | SplitNewTodoFromAt Todo Time
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
    CreateNewTodo


splitNewTodoFrom =
    SplitNewTodoFrom


start =
    Start


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
