module TodoAction exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type TodoUpdateActionType
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | Delete


type alias UpdateActionTA =
    { now : Time, action : TodoUpdateActionType, id : TodoId }


type TodoAction
    = Update UpdateActionTA
    | Add String Time
