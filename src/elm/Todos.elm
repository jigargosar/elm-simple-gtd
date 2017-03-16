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
        , rejectMap
        )

import Dict
import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todos.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import Dict.Extra as Dict
import FunctionalHelpers exposing (..)
import Todos.Model as Model exposing (Todos)


type TodosModel
    = TodosModel Todos


initWithSeed =
    Model.initWithTodos [] >> TodosModel


reject filter (TodosModel todos) =
    FunctionalHelpers.reject filter todos.todoList


rejectMap filter mapper (TodosModel todos) =
    todos.todoList |> List.filterMap (ifElse (filter >> not) (mapper >> Just) (\_ -> Nothing))


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


deleteTodo : TodoId -> TodosModel -> ( TodosModel, Maybe Todo )
deleteTodo todoId (TodosModel todos) =
    let
        todoList =
            todos.todoList
                |> List.updateIf (Todo.hasId todoId) (Todo.markDeleted)
    in
        ( setTodoList todoList todos |> TodosModel
        , List.find (Todo.hasId todoId) todoList
        )


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
