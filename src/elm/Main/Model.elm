module Main.Model exposing (..)

import Main.Msg exposing (Msg)
import Return exposing (Return)
import Todos exposing (EditMode(EditNewTodoMode, NotEditing), TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)
import Todos.Todo exposing (TodoId)
import Toolkit.Operators exposing (..)
import Toolkit.Helpers exposing (..)


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
    Return.map (\m -> { m | editMode = editMode })


getEditMode =
    (.editMode)


activateAddNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


setTodosModel todosModel =
    Return.map (\m -> { m | todosModel = todosModel })


addNewTodoAnddeactivateAddNewTodoMode : Return Msg Model -> Return Msg Model
addNewTodoAnddeactivateAddNewTodoMode =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry createAndAddNewTodo)
        >> setEditModeTo NotEditing


createAndAddNewTodo editMode =
    case editMode of
        EditNewTodoMode text ->
            Return.map (\m -> ( Todos.addNewTodo text m.todosModel, Return.singleton m ))
                >> Return.andThen (uncurry setTodosModel)

        _ ->
            identity
