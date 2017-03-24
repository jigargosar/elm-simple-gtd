module TodoGroupViewModel exposing (..)

import Todo exposing (TodoGroup, TodoList)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias TodoGroupViewModel =
    { group : TodoGroup, displayName : String, todoList : TodoList }
