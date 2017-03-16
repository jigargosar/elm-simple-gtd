module Todos.Model exposing (..)

import FunctionalHelpers exposing (..)
import Random.Pcg as Random exposing (Seed)
import Todos.Todo as Todo exposing (Todo)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Dict
import Dict.Extra as Dict


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Model =
    { todoList : List Todo
    , seed : Seed
    }


init todos seed =
    Model todos seed


getTodoList =
    (.todoList)


rejectMap filter mapper =
    getTodoList >> List.filterMap (ifElse (filter >> not) (mapper >> Just) (\_ -> Nothing))


setSeed seed todos =
    { todos | seed = seed }


getSeed =
    (.seed)


append todo todos =
    todos.todoList ++ [ todo ] |> setTodoList # todos


setTodoList todoList todos =
    { todos | todoList = todoList }


generateTodo text todos =
    Random.step (Todo.todoGenerator text) (getSeed todos)


addNewTodo text todos =
    let
        ( todo, seed ) =
            generateTodo text todos
    in
        ( todos |> append todo |> setSeed seed, todo )


replaceTodoIfIdMatches todo todos =
    let
        todoList =
            todos.todoList
                |> List.replaceIf (Todo.equalById todo) todo
    in
        ( todos |> setTodoList todoList, todo )


upsertTodoList upsertList todos =
    let
        finalTodoList : List Todo
        finalTodoList =
            Todo.fromListById todos.todoList
                |> Dict.union (Todo.fromListById upsertList)
                |> Dict.values
    in
        todos |> setTodoList finalTodoList
