module ActiveTodoState exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time Time
    | Stopped


type alias ActiveTodoState =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    ActiveTodoState id (Started now now) 0 now |> Just


getMaybeId =
    Maybe.map (.id)


getElapsedTime now activeTodoState =
    case activeTodoState.state of
        Started startedAt lastBeepedAt ->
            (now - startedAt) + activeTodoState.timeSpent

        Stopped ->
            activeTodoState.timeSpent
