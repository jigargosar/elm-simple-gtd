module Main.Msg exposing (..)

import Dom
import DomTypes exposing (DomMsg)
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.TodoListMsg exposing (TodoListMsg)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroupType, TodoId)
import ViewState exposing (ViewState)


type Msg
    = NoOp
    | OnAddTodoClicked Dom.Id
    | OnDeleteTodoClicked TodoId
    | OnEditTodoClicked Dom.Id Todo
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoKeyUp String Key
    | OnEditTodoTextChanged String
    | OnEditTodoBlur Todo
    | OnTodoDoneClicked TodoId
    | OnEditTodoKeyUp Todo Key
    | OnSetTodoGroupClicked TodoGroupType Todo
    | OnShowTodoList
    | OnShowBin
    | OnTodoListMsg TodoListMsg
    | OnDomMsg DomMsg
    | ChangeViewState ViewState
