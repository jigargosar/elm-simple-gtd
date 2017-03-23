module Main.TodoListMsg exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type UpdateAction
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | Delete


type alias UpdateActionTA =
    { now : Time, action : UpdateAction }


type TodoListMsg
    = UpdateTodoAt UpdateAction TodoId Time
    | UpdateTodo UpdateAction TodoId
    | AddNewTodo String
    | AddNewTodoAt String Time
