module TodoListTypes exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type UpdateAction
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | ToggleDelete


type TodoMsg
    = UpdateTodoAt UpdateAction TodoId Time
    | UpdateTodo UpdateAction TodoId
    | AddNewTodo String
    | AddNewTodoAt String Time
    | Start TodoId
    | Stop
    | StopAndMarkDone
