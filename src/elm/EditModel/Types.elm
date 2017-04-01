module EditModel.Types exposing (..)

import Project
import Todo exposing (Todo, TodoText)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias EditTodoModel =
    { todo : Todo, todoText : TodoText, projectName : Project.ProjectName }


type alias NewTodoModel =
    TodoText


type EditModel
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | None
