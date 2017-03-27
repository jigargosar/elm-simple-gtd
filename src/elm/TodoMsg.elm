module TodoMsg exposing (..)

import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type UpdateAction
    = ToggleDone
    | MarkDone
    | SetGroup TodoGroup
    | SetText String
    | ToggleDelete


type TodoMsg
    = UpdateTodoAt UpdateAction TodoId Time
    | UpdateTodo UpdateAction TodoId
    | SaveNewTodo String
    | SaveNewTodoAt String Time
    | SplitNewTodoFrom Todo
    | SplitNewTodoFromAt Todo Time
    | Start TodoId
    | Stop
    | StopAndMarkDone


toggleDone =
    UpdateTodo ToggleDone


markDone =
    UpdateTodo MarkDone


toggleDelete =
    UpdateTodo ToggleDelete


setGroup group =
    UpdateTodo (SetGroup group)


setText text =
    UpdateTodo (SetText text)


saveNewTodo =
    SaveNewTodo


splitNewTodoFrom =
    SplitNewTodoFrom


start =
    Start


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
