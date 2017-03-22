module Main.Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.TodoListMsg exposing (TodoListMsg)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)


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
    | OnEditTodoBlur Todo
    | OnTodoDoneClicked TodoId
    | OnEditTodoKeyUp Todo Key
    | OnSetTodoGroupClicked TodoGroup Todo
    | OnShowTodoList
    | ProcessInbox
    | OnSaveNewTodoAndContinueAdding Time
    | OnTodoListMsg TodoListMsg
