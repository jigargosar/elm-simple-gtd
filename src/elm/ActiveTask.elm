module ActiveTask exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time
    | Stopped


type alias MaybeTask =
    Maybe Task


type alias Task =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    Task id (Started now) 0 now |> Just


getTodoId =
    (.id)


getElapsedTime now task =
    case task.state of
        Started time ->
            (now - time) + task.timeSpent

        Stopped ->
            task.timeSpent
