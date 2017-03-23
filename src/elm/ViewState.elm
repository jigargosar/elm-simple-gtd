module ViewState exposing (..)

import InboxFlow
import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type ViewState
    = AllTodoListsViewState
    | InboxFlowViewState (Maybe Todo) InboxFlow.Model


default =
    AllTodoListsViewState
