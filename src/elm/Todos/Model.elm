module Todos.Model exposing (..)

import FunctionalHelpers
import Random.Pcg as Random exposing (Seed)
import Todos.Todo as Todo exposing (Todo)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Model =
    { todoList : List Todo
    , seed : Seed
    }


initWithTodos todos seed =
    Model todos seed

getTodoList = (.todoList)


reject filter todos =
    FunctionalHelpers.reject filter todos.todoList
