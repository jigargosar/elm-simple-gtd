module Main.Msg exposing (..)

import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Navigation exposing (Location)
import TodoCollection.Todo exposing (Todo, TodoId)


type Msg
    = LocationChanged Location
    | OnAddTodoClicked
    | OnDeleteTodoClicked TodoId
    | OnEditTodoClicked Todo
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoEnterPressed
    | OnEditTodoTextChanged String
    | OnEditTodoBlur
    | OnEditTodoEnterPressed
    | OnFlowTrashItClicked
    | OnYesClicked
    | OnNoClicked
    | OnBackClicked
    | OnInBasketFlowAction FlowAction
    | OnShowTodoList
    | OnProcessInBasket
