module TodoList.Types exposing (..)

import Todo.Types exposing (EncodedTodo, Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type alias TodoList =
    List Todo


type alias EncodedTodoList =
    List EncodedTodo
