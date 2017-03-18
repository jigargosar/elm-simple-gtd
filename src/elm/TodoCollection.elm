module TodoCollection
    exposing
        ( --types
          TodoCollection
        , EditMode(..)
          -- init
        , todoModelGenerator
          -- crud
        , addNewTodo
        , deleteTodo
        , replaceTodoIfIdMatches
          -- for views
        , rejectMap
          -- temp
        , asList__
        , getInBasketTodoList__
        )

import Dict
import Dict.Extra as Dict
import Random.Pcg as Random exposing (Seed)
import RandomIdGenerator
import TodoCollection.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import FunctionalHelpers exposing (..)
import TodoCollection.Model as Model exposing (Model)
import Tuple2


type TodoCollection
    = TodoCollection Model


toModel (TodoCollection model) =
    model



-- temp


asList__ =
    toModel >> Model.getTodoList


getInBasketTodoList__ : TodoCollection -> List Todo
getInBasketTodoList__ =
    toModel >> Model.getInBasketTodoList



-- external


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


todoModelGenerator : List Todo -> Random.Generator TodoCollection
todoModelGenerator todoList =
    Random.map (Model.init todoList >> TodoCollection) Random.independentSeed


deleteTodo : TodoId -> TodoCollection -> ( TodoCollection, Maybe Todo )
deleteTodo todoId =
    toModel >> Model.deleteTodo todoId >> Tuple2.mapFirst TodoCollection


replaceTodoIfIdMatches todo =
    toModel >> Model.replaceTodoIfIdMatches todo >> Tuple2.mapFirst TodoCollection


addNewTodo text =
    toModel >> Model.addNewTodo text >> Tuple2.mapFirst TodoCollection



-- view external


rejectMap filter mapper =
    toModel >> Model.rejectMap filter mapper
