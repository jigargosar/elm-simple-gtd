module ActiveTask exposing (..)

import Time exposing (Time)
import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Started Time
    | Stopped


type ActiveTask
    = None
    | Some Task


type alias Task =
    { id : TodoId, state : State, timeSpent : Time, startTime : Time }


init =
    None


start id now =
    Task id (Started now) 0 now |> Some
