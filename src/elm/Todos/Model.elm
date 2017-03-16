module Todos.Model exposing (..)

import FunctionalHelpers exposing (..)
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


getTodoList =
    (.todoList)


reject filter todos =
    FunctionalHelpers.reject filter todos.todoList


rejectMap filter mapper =
    getTodoList >> List.filterMap (ifElse (filter >> not) (mapper >> Just) (\_ -> Nothing))


setSeed seed todos =
    { todos | seed = seed }


append todo todos =
    todos.todoList ++ [ todo ] |> setTodoList # todos


setTodoList todoList todos =
    { todos | todoList = todoList }

