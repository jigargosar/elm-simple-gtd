module Main.Msg exposing (..)

import Dom
import DomTypes exposing (DomMsg)
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.TodoListMsg exposing (TodoListMsg)
import Main.Types exposing (ViewType)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)


type Msg
    = NoOp
    | OnAddTodoClicked Dom.Id
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoKeyUp String Key
      --
    | OnDeleteTodoClicked TodoId
    | OnEditTodoClicked Dom.Id Todo
      --
    | OnEditTodoTextChanged String
    | OnEditTodoBlur Todo
    | OnTodoDoneClicked TodoId
    | OnEditTodoKeyUp Todo Key
    | OnSetTodoGroupClicked TodoGroup Todo
    | OnTodoListMsg TodoListMsg
    | OnDomMsg DomMsg
    | ChangeView ViewType
    | UpdateNow Time
