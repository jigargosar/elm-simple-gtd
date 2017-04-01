module EditModel.Types exposing (..)

import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import TodoModel.Types exposing (..)


type EditModel
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | None
