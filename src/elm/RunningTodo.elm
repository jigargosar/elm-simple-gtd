module RunningTodo exposing (..)

import Time exposing (Time)
import Todo
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import Ext.Function exposing (..)
import Ext.Function.Infix exposing (..)
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


start todo now =
    RunningTodo (Todo.getId todo) (createStartedState now now) 0 now |> Just


getId =
    (.id)


getElapsedTime now runningTodo =
    case runningTodo.state of
        Running { startedAt, lastBeepedAt } ->
            (now - startedAt) + runningTodo.timeSpent

        Stopped ->
            runningTodo.timeSpent


getMaybeRunningState runningTodo =
    case runningTodo.state of
        Running runningState ->
            Just runningState

        _ ->
            Nothing


setLastBeepedAt now runningTodo =
    getMaybeRunningState runningTodo
        ?|> (\runningState ->
                { runningTodo
                    | state =
                        Running { runningState | lastBeepedAt = now }
                }
            )
        ?= runningTodo


shouldBeep now runningTodo =
    case runningTodo.state of
        Running { lastBeepedAt } ->
            now - lastBeepedAt > 10 * Time.minute

        _ ->
            False
