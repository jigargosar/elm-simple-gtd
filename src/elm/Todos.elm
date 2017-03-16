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
import Dict.Extra as Dict
import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import Todos.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import FunctionalHelpers exposing (..)
import Todos.Model as Model exposing (Model, append, setSeed, setTodoList)
import Tuple2


type TodosModel
    = TodosModel Model


initWithSeed =
    Model.initWithTodos [] >> TodosModel


withModel fn (TodosModel model) =
    fn model


toModel (TodosModel model) =
    model


reject filter =
    toModel >> Model.reject filter


rejectMap filter mapper =
    toModel >> Model.rejectMap filter mapper



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
upsertTodoList upsertList =
    toModel >> Model.upsertTodoList upsertList >> TodosModel


replaceTodoIfIdMatches todo =
    toModel >> Model.replaceTodoIfIdMatches todo >> Tuple2.mapFirst TodosModel


addNewTodo text =
    toModel >> Model.addNewTodo text >> Tuple2.mapFirst TodosModel
