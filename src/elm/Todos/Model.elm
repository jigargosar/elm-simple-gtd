module Todos.Model exposing (..)

import Random.Pcg as Random exposing (Seed)
import Todos.Todo as Todo exposing (Todo)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Todos =
    { todoList : List Todo
    , seed : Seed
    }


initWithTodos todos seed =
    Todos todos seed

getTodoList = (.todoList)


