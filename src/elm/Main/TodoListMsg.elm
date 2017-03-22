module Main.TodoListMsg exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type Action
    = ToggleDone
    | SetGroup TodoGroup
    | Delete


type TodoListMsg
    = UpdateTodoAt Action TodoId Time
    | UpdateTodo Action TodoId


