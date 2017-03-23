module ViewState exposing (..)

import Todo exposing (Todo)
import Toolkit.Helpers exposing (..)
import Toolkit.Operators exposing (..)
import FunctionExtra exposing (..)


type NavigationAction
    = ShowAllTodoLists
    | StartProcessingInbox

type TodoListViewState = All


type ViewState = TodoList TodoListViewState
