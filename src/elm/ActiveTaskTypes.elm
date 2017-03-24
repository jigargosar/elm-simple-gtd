module ActiveTaskTypes exposing (..)

import Todo exposing (TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type State
    = Running
    | Paused


type ActiveTask
    = None
    | Some TodoId State
