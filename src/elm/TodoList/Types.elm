module TodoList.Types exposing (..)

import Todo.Types exposing (EncodedTodo, Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)


type alias TodoList =
    List Todo


type alias EncodedTodoList =
    List EncodedTodo
