module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)


type TodoEditAction
    = SetGroup
    | ToggleDone
    | Delete


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
    | OnTodoDoneClicked TodoId
    | OnEditTodoKeyUp Key
    | OnTodoMoveToClicked TodoGroup Todo
    | MoveTodoToListTypeWithNow TodoGroup Todo Time
    | MoveFlowTodoToListTypeWithNow TodoGroup Time
    | OnFlowMoveTo TodoGroup
    | OnInboxFlowAction FlowAction
    | OnShowTodoList
    | OnProcessInbox
    | OnFlowMarkDeleted
    | OnSaveNewTodoAndContinueAdding Time
    | SaveEditingTodoWithNow Time
