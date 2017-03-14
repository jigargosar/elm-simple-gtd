module Todos exposing (..)

import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todos.Todo as Todo exposing (Todo, TodoId)


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
    = AddingNewTodo
    | EditTodo TodoId
    | NotEditing

