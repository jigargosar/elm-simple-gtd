module Todos exposing (..)

import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todos.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


type ProjectType
    = InboxProject
    | CustomProject


type alias Project =
    { id : String, name : String, type_ : ProjectType }


type alias Todos =
    { todoList : List Todo
    , seed : Seed
    }


type TodosModel
    = TodosModel Todos


todoModelGenerator : Random.Generator TodosModel
todoModelGenerator =
    Random.map initWithSeed Random.independentSeed


initWithSeed =
    generateTestTodo >> uncurry initWithTodo


generateTestTodo =
    Random.step (todoListGenerator)


todoListGenerator : Random.Generator (List Todo)
todoListGenerator =
    Random.list 10 (Todo.todoGenerator "foo")


initWithTodo todos seed =
    TodosModel (Todos todos seed)


map mapper (TodosModel todos) =
    List.map mapper todos.todoList


type EditMode
    = EditNewTodoMode String
    | EditTodo TodoId
    | NotEditing


addNewTodo text (TodosModel todos) =
    let
        ( todo, seed ) =
            generateTodo text todos.seed
    in
        todos |> append todo |> setSeed seed |> TodosModel


setSeed seed todos =
    { todos | seed = seed }


append todo todos =
    todos.todoList ++ [ todo ] |> setTodoList # todos


setTodoList todoList todos =
    { todos | todoList = todoList }


generateTodo text =
    Random.step (Todo.todoGenerator text)
