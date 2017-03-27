module TodoListMsg exposing (..)

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
    | AddNewTodo String
    | AddNewTodoAt String Time
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


setGroup : TodoGroup -> TodoId -> TodoMsg
setGroup =
    SetGroup >> UpdateTodo


setText : String -> TodoId -> TodoMsg
setText =
    SetText >> UpdateTodo


addNewTodo : String -> TodoMsg
addNewTodo =
    AddNewTodo


splitNewTodoFrom : Todo -> TodoMsg
splitNewTodoFrom =
    SplitNewTodoFrom


stop =
    Stop


stopAndMarkDone =
    StopAndMarkDone
