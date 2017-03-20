module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Navigation exposing (Location)
import Todo exposing (ListType, Todo, TodoId)


type Msg
    = NoOp
    | LocationChanged Location
    | OnAddTodoClicked Dom.Id
    | OnDeleteTodoClicked TodoId
    | OnEditTodoClicked Dom.Id Todo
    | OnDomFocusResult (Result Dom.Error ())
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoKeyUp Key
    | OnEditTodoTextChanged String
    | OnEditTodoBlur
    | OnEditTodoKeyUp Key
    | OnFlowTrashItClicked
    | OnFlowMoveToSomeDayMaybe
    | OnFlowMoveTo ListType
    | OnFlowMoveToUnder2mList
    | OnYesClicked
    | OnNoClicked
    | OnBackClicked
    | OnInBasketFlowAction FlowAction
    | OnShowTodoList
    | OnProcessInBasket
    | OnFlowMarkDeleted
