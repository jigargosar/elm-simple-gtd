module RunningTodoDetails exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)


type alias RunningState =
    { startedAt : Time, lastBeepedAt : Time }


type State
    = Running RunningState
    | Stopped


createStartedState =
    RunningState >>> Running


type alias RunningTodoDetails =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    Nothing


start id now =
    RunningTodoDetails id (createStartedState now now) 0 now |> Just


getMaybeId =
    Maybe.map (.id)


getElapsedTime now runningTodoDetails =
    case runningTodoDetails.state of
        Running { startedAt, lastBeepedAt } ->
            (now - startedAt) + runningTodoDetails.timeSpent

        Stopped ->
            runningTodoDetails.timeSpent
