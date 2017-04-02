module EditModel.Types exposing (..)

import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Todo.Types exposing (..)


type alias EditTodoModel =
    { todo : Todo, todoText : TodoText, projectName : Project.ProjectName }


type alias NewTodoModel =
    TodoText


type EditModel
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | None
