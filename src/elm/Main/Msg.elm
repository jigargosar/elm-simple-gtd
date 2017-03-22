module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)


type TodoAction
    = SetGroup TodoGroup
    | ToggleDone
    | Delete


type UpdateTodoAction
    = UpdateTodoWithNow TodoAction TodoId Time
    | UpdateTodoWithAction TodoAction TodoId


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
    | OnSetTodoGroupClicked TodoGroup Todo
    | OnShowTodoList
    | OnProcessInbox
    | OnSaveNewTodoAndContinueAdding Time
    | SaveEditingTodoWithNow Time
    | UpdateTodo TodoAction TodoId Time
