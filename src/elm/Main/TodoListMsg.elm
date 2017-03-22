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


type alias AtTime a =
    { a | at : Time }


type alias Action =
    { id : TodoId
    , actionType : ActionType
    }


type alias ActionAt =
    AtTime Action


type Msg
    = UpdateTodoAt ActionAt
    | UpdateTodo Action
