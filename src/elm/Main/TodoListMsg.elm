module Main.TodoListMsg exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type ActionType
    = ToggleDone
    | SetGroup TodoGroup
    | Delete


type alias Action =
    { id : TodoId
    , type_ : ActionType
    }


type Msg
    = UpdateTodoAt Action Time
    | UpdateTodo Action
