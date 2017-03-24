module ViewState exposing (..)

import Todo exposing (Todo, TodoGroupType)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type ViewState
    = AllGrouped
    | Group TodoGroupType
    | Done
    | Bin


defaultViewState =
    AllGrouped
