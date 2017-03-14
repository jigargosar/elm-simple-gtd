module Main.Model exposing (..)

import Return
import Todos exposing (TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todos.Todo exposing (TodoId)


type EditMode
    = AddTodo
    | EditTodo TodoId
    | NotEditing


type alias Model =
    { todosModel : TodosModel
    , editMode : EditMode
    }


initWithTime : Time -> Model
initWithTime =
    round >> Random.initialSeed >> initWithSeed


initWithSeed seed =
    { todosModel = Random.step Todos.todoModelGenerator seed |> Tuple.first
    , editMode = NotEditing
    }


getTodosModel =
    (.todosModel)


setEditModeTo editMode =
    Return.map (\m -> { m | editMode = AddTodo })


activateAddTodoMode =
    setEditModeTo AddTodo
