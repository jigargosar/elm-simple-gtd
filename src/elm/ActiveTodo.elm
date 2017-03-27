module ActiveTodo exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time Time
    | Stopped


type alias MaybeActiveTodo =
    Maybe ActiveTodo


type alias ActiveTodo =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    ActiveTodo id (Started now now) 0 now |> Just


getMaybeId =
    Maybe.map (.id)


getElapsedTime now activeTodo =
    case activeTodo.state of
        Started startedAt lastBeepedAt ->
            (now - startedAt) + activeTodo.timeSpent

        Stopped ->
            activeTodo.timeSpent

