module TodoStore.Model exposing (..)

import FunctionExtra exposing (..)
import Random.Pcg as Random exposing (Seed)
import Todo as Todo exposing (Todo, TodoList)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)
import List.Extra as List
import Dict exposing (Dict)
import Dict.Extra as Dict
import Tuple2


type alias Model =
    { todoList : TodoList
    , seed : Seed
    }


init todoStore seed =
    Model todoStore seed


generator : TodoList -> Random.Generator Model
generator todoList =
    Random.map (init todoList) Random.independentSeed


getTodoList =
    (.todoList)


mapAllExceptDeleted mapper =
    getTodoList >> Todo.mapAllExceptDeleted mapper


getTodoLists : Model -> List ( String, List Todo )
getTodoLists =
    getTodoList >> Todo.todoListsByType


getTodoLists2 =
    getTodoList >> Todo.todoListsByType2


getInboxTodoList : Model -> TodoList
getInboxTodoList =
    mapAllExceptDeleted identity


getFirstInboxTodo : Model -> Maybe Todo
getFirstInboxTodo =
    getTodoList >> Todo.getFirstInboxTodo


setSeed seed todoStore =
    { todoStore | seed = seed }


getSeed =
    (.seed)


appendTodo todo todoStore =
    todoStore.todoList ++ [ todo ] |> setTodoList # todoStore


setTodoList todoList model =
    { model | todoList = todoList }


updateTodoList fun model =
    setTodoList (fun model) model


generate generator todoStore =
    Random.step generator (getSeed todoStore)
        |> Tuple2.mapSecond (setSeed # todoStore)


addNewTodo text todoStore =
    let
        ( todo, newTodoCollection ) =
            generate (Todo.generator text) todoStore
    in
        ( appendTodo todo newTodoCollection, todo )


replaceTodoIfIdMatches : Todo -> Model -> ( Model, Todo )
replaceTodoIfIdMatches todo =
    let
        newTodoList =
            getTodoList >> Todo.replaceIfEqualById todo
    in
        updateTodoList newTodoList >> (,) # todo


deleteTodo todoId todoStore =
    let
        todoList =
            todoStore.todoList
                |> List.updateIf (Todo.hasId todoId) (Todo.markDeleted)
    in
        ( setTodoList todoList todoStore
        , List.find (Todo.hasId todoId) todoList
        )
