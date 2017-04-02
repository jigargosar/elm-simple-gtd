module EditModel.Types exposing (..)

import Project
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import Todo.Types exposing (..)


type alias EditTodoModel =
    { todo : TodoModel, todoText : TodoText, projectName : Project.ProjectName }


type alias NewTodoModel =
    TodoText


type EditModel
    = NewTodo NewTodoModel
    | EditTodo EditTodoModel
    | None
