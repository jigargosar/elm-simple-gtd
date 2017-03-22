module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoId)


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
    | OnTodoMoveToClicked Todo.Group Todo
    | MoveTodoToListTypeWithNow Todo.Group Todo Time
    | MoveFlowTodoToListTypeWithNow  Todo.Group Time
    | OnFlowMoveTo Todo.Group
    | OnInboxFlowAction FlowAction
    | OnShowTodoList
    | OnProcessInbox
    | OnFlowMarkDeleted
    | OnSaveNewTodoAndContinueAdding Time
    | SaveEditingTodoWithNow Time
