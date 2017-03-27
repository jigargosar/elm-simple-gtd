module RunningTodoDetails exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time Time
    | Stopped


type alias RunningTodoDetails =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    RunningTodoDetails id (Started now now) 0 now |> Just


getMaybeId =
    Maybe.map (.id)


getElapsedTime now runningTodoDetails =
    case runningTodoDetails.state of
        Started startedAt lastBeepedAt ->
            (now - startedAt) + runningTodoDetails.timeSpent

        Stopped ->
            runningTodoDetails.timeSpent
