module Main.TodoListMsg exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type TodoActionType
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | Delete


type alias UpdateActionTA =
    { now : Time, action : TodoActionType }


type TodoListMsg
    = UpdateTodoAt TodoActionType TodoId Time
    | UpdateTodo TodoActionType TodoId
    | AddNewTodo String
    | AddNewTodoAt String Time
