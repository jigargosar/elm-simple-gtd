module Main.Model exposing (..)

import Return
import Todos exposing (TodosModel)
import Random.Pcg as Random exposing (Seed)
import Time exposing (Time)


type alias Model =
    { todosModel : TodosModel }


initWithTime : Time -> Model
initWithTime =
    round >> Random.initialSeed >> initWithSeed


initWithSeed seed =
    { todosModel = Random.step Todos.todoModelGenerator seed |> Tuple.first }
