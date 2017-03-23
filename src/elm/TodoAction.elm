module TodoAction exposing (..)

import Time exposing (Time)
import Todo exposing (TodoGroup, TodoId)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type EditAction
    = ToggleDone
    | SetGroup TodoGroup
    | SetText String
    | Delete


type TodoAction
    = Edit EditAction TodoId Time
    | New String Time
