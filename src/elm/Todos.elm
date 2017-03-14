module Todos exposing (..)

import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
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


type TodosModel
    = TodosModel Todos


todoModelGenerator : Random.Generator TodosModel
todoModelGenerator =
    Random.map initWithSeed Random.independentSeed


initWithSeed =
    generateTestTodo >> uncurry initWithTodo


generateTestTodo =
    Random.step (Todo.todoGenerator "foo")


initWithTodo todo seed =
    TodosModel (Todos [ todo ] seed)



map mapper (TodosModel todos) =
    List.map mapper todos.todoList
