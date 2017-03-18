module TodoCollection.Model exposing (..)

import FunctionalHelpers exposing (..)
import Random.Pcg as Random exposing (Seed)
import TodoCollection.Todo as Todo exposing (Todo)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Dict
import Dict.Extra as Dict
import Tuple2


type alias Model =
    { todoList : List Todo
    , seed : Seed
    }


init todoCollection seed =
    Model todoCollection seed


getTodoList =
    (.todoList)


rejectMap filter mapper =
    getTodoList >> List.filterMap (ifElse (filter >> not) (mapper >> Just) (\_ -> Nothing))


getInBasketTodoList : Model -> List Todo
getInBasketTodoList =
    rejectMap Todo.isDeleted identity


setSeed seed todoCollection =
    { todoCollection | seed = seed }


getSeed =
    (.seed)


appendTodo todo todoCollection =
    todoCollection.todoList ++ [ todo ] |> setTodoList # todoCollection


setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList fun model =
    setTodoList (fun model) model


generate generator todoCollection =
    Random.step generator (getSeed todoCollection)
        |> Tuple2.mapSecond (setSeed # todoCollection)


addNewTodo text todoCollection =
    let
        ( todo, newTodoCollection ) =
            generate (Todo.todoGenerator text) todoCollection
    in
        ( appendTodo todo newTodoCollection, todo )


replaceTodoIfIdMatches : Todo -> Model -> ( Model, Todo )
replaceTodoIfIdMatches todo =
    let
        newTodoList =
            getTodoList >> Todo.replaceIfEqualById todo
    in
        updateTodoList newTodoList >> (,) # todo


upsertTodoList upsertList =
    let
        finalTodoList : Model -> List Todo
        finalTodoList =
            getTodoList
                >> Todo.fromListById
                >> Dict.union (Todo.fromListById upsertList)
                >> Dict.values
    in
        updateTodoList finalTodoList


deleteTodo todoId todoCollection =
    let
        todoList =
            todoCollection.todoList
                |> List.updateIf (Todo.hasId todoId) (Todo.markDeleted)
    in
        ( setTodoList todoList todoCollection
        , List.find (Todo.hasId todoId) todoList
        )
