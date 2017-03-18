module TodoStore
    exposing
        ( --types
          TodoStore
        , EditMode(..)
          -- init
        , generator
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
import TodoStore.Todo as Todo exposing (Todo, TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Maybe.Extra as Maybe
import FunctionalHelpers exposing (..)
import TodoStore.Model as Model exposing (Model)
import Tuple2


type alias TodoStore =
    Model.Model


toModel =
    identity



-- temp


getInBasketTodoList__ : TodoStore -> TodoList
getInBasketTodoList__ =
    toModel >> Model.getInBasketTodoList



-- external


type EditMode
    = EditNewTodoMode String
    | EditTodoMode Todo
    | NotEditing


generator =
    Model.generator


deleteTodo =
    Model.deleteTodo


replaceTodoIfIdMatches =
    Model.replaceTodoIfIdMatches


addNewTodo =
    Model.addNewTodo
