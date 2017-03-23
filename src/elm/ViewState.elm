module ViewState exposing (..)

import Todo exposing (Todo, TodoGroup)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type ViewState
    = AllGrouped
    | Group TodoGroup
    | Done
    | Bin


defaultViewState =
    AllGrouped
