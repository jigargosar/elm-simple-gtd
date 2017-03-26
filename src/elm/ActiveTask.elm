module ActiveTask exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time Time
    | Stopped


type alias MaybeActiveTask =
    Maybe Task


type alias Task =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    Task id (Started now now) 0 now |> Just


getTodoId =
    (.id)


getElapsedTime now task =
    case task.state of
        Started startedAt lastBeepedAt ->
            (now - startedAt) + task.timeSpent

        Stopped ->
            task.timeSpent
