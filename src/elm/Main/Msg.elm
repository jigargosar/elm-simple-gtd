module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Group, Todo, TodoId)


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
    | OnTodoMoveToClicked Group Todo
    | OnFlowMoveTo Group
    | OnInboxFlowAction FlowAction
    | OnShowTodoList
    | OnProcessInbox
    | OnFlowMarkDeleted
    | OnSaveNewTodoAndContinueAdding Time
