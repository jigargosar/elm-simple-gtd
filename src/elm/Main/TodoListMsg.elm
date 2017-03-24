module Main.TodoListMsg exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroupType, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type TodoUpdateActionType
    = ToggleDone
    | SetGroup TodoGroupType
    | SetText String
    | Delete


type TodoListMsg
    = UpdateTodoAt TodoUpdateActionType TodoId Time
    | UpdateTodo TodoUpdateActionType TodoId
    | AddNewTodo String
    | AddNewTodoAt String Time
