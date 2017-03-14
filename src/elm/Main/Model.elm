module Main.Model exposing (..)

import Return
import Todos exposing (EditMode(AddingNewTodo, NotEditing), TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todos.Todo exposing (TodoId)


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
    Return.map (\m -> { m | editMode = AddingNewTodo })


getEditMode =
    (.editMode)


activateAddTodoMode text =
    setEditModeTo (AddingNewTodo text)
