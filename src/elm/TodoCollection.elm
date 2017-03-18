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
          -- temp
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


type alias TodoCollection =
    Model.Model


toModel =
    identity



-- temp


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
    Random.map (Model.init todoList) Random.independentSeed


deleteTodo =
    Model.deleteTodo


replaceTodoIfIdMatches =
    Model.replaceTodoIfIdMatches


addNewTodo =
    Model.addNewTodo
