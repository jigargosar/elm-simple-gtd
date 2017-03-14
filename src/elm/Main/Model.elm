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


type alias ReturnMapper =
    Return Msg Model -> Return Msg Model


initWithTime : Time -> Model
initWithTime =
    round >> Random.initialSeed >> initWithSeed


initWithSeed : Seed -> Model
initWithSeed seed =
    { todosModel = Random.step Todos.todoModelGenerator seed |> Tuple.first
    , editMode = NotEditing
    }


getTodosModel : Model -> TodosModel
getTodosModel =
    (.todosModel)


setEditModeTo : EditMode -> ReturnMapper
setEditModeTo editMode =
    Return.map (\m -> { m | editMode = editMode })


getEditMode : Model -> EditMode
getEditMode =
    (.editMode)


activateAddNewTodoMode : String -> ReturnMapper
activateAddNewTodoMode text =
    setEditModeTo (EditNewTodoMode text)


setTodosModel : TodosModel -> ReturnMapper
setTodosModel todosModel =
    Return.map (\m -> { m | todosModel = todosModel })


addNewTodoAndDeactivateAddNewTodoMode : ReturnMapper
addNewTodoAndDeactivateAddNewTodoMode =
    addNewTodo
        >> setEditModeTo NotEditing


addNewTodoAndContinueAdding : ReturnMapper
addNewTodoAndContinueAdding =
    addNewTodo
        >> activateAddNewTodoMode ""


addNewTodo : ReturnMapper
addNewTodo =
    Return.map (\m -> ( getEditMode m, Return.singleton m ))
        >> Return.andThen (uncurry createAndAddNewTodo)


createAndAddNewTodo : EditMode -> ReturnMapper
createAndAddNewTodo editMode =
    case editMode of
        EditNewTodoMode text ->
            Return.map (\m -> ( Todos.addNewTodo text m.todosModel, Return.singleton m ))
                >> Return.andThen (uncurry setTodosModel)

        _ ->
            identity
