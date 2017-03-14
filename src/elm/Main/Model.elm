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


addNewTodo text =
    Return.map (\m -> ( Todos.addNewTodo text m.todosModel, Return.singleton m ))
        >> Return.andThen (uncurry setTodosModel)


setTodosModel todosModel =
    Return.map (\m -> { m | todosModel = todosModel })


deactivateAddNewTodoMode : Return Msg Model -> Return Msg Model
deactivateAddNewTodoMode =
    Return.andThen
        (\m ->
            m
                |> (Return.singleton
                        >> (case getEditMode m of
                                EditNewTodoMode text ->
                                    addNewTodo text
                                        >> setEditModeTo NotEditing

                                _ ->
                                    setEditModeTo NotEditing
                           )
                   )
        )
