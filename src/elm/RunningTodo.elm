module RunningTodo exposing (..)

import Time exposing (Time)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)
import FunctionExtra.Operators exposing (..)
import Todo.Types exposing (TodoId)


type alias RunningState =
    { startedAt : Time, lastBeepedAt : Time }


type State
    = Running RunningState
    | Stopped


createStartedState =
    RunningState >>> Running


type alias RunningTodo =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


start id now =
    RunningTodo id (createStartedState now now) 0 now |> Just


getMaybeId =
    Maybe.map (.id)


getElapsedTime now runningTodo =
    case runningTodo.state of
        Running { startedAt, lastBeepedAt } ->
            (now - startedAt) + runningTodo.timeSpent

        Stopped ->
            runningTodo.timeSpent
