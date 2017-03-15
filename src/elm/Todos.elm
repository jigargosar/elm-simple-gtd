module Todos
    exposing
        ( --types
          TodosModel
        , EditMode(..)
          -- init
        , todoModelGenerator
        , upsertTodoList
          -- crud
        , addNewTodo
        , deleteTodo
        , replaceTodoIfIdMatches
          -- for views
        , map
        )

import Dict
import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todos.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Dict.Extra as Dict


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


initWithSeed =
    initWithTodos []


initWithTodos todos seed =
    TodosModel (Todos todos seed)


map mapper (TodosModel todos) =
    List.map mapper todos.todoList


setSeed seed todos =
    { todos | seed = seed }


append todo todos =
    todos.todoList ++ [ todo ] |> setTodoList # todos


setTodoList todoList todos =
    { todos | todoList = todoList }


generateTodo text =
    Random.step (Todo.todoGenerator text)



-- external


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


todoModelGenerator : Random.Generator TodosModel
todoModelGenerator =
    Random.map initWithSeed Random.independentSeed


deleteTodo todoId (TodosModel todos) =
    todos.todoList
        |> List.filter (\todo -> todoId /= (Todo.getId todo))
        |> (setTodoList # todos)
        |> TodosModel


upsertTodoList : List Todo -> TodosModel -> TodosModel
upsertTodoList upsertList (TodosModel todos) =
    let
        finalTodoList : List Todo
        finalTodoList =
            Todo.fromListById todos.todoList
                |> Dict.union (Todo.fromListById upsertList)
                |> Dict.values
    in
        todos |> setTodoList finalTodoList |> TodosModel


replaceTodoIfIdMatches todo (TodosModel todos) =
    let
        todoList =
            todos.todoList
                |> List.replaceIf (Todo.equalById todo) todo
    in
        ( todos |> setTodoList todoList |> TodosModel, todo )


addNewTodo text (TodosModel todos) =
    let
        ( todo, seed ) =
            generateTodo text todos.seed
    in
        ( todos |> append todo |> setSeed seed |> TodosModel, todo )
