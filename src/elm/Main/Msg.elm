module Main.Msg exposing (..)

import Dom
import DomTypes exposing (DomMsg)
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.TodoListMsg exposing (TodoMsg)
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
      --
    | OnEditTodoClicked Dom.Id Todo
    | OnEditTodoTextChanged String
    | OnEditTodoBlur Todo
    | OnEditTodoKeyUp Todo Key
      --
    | OnDeleteTodoClicked TodoId
    | OnTodoDoneClicked TodoId
    | OnSetTodoGroupClicked TodoGroup Todo
      --
    | OnTodoMsg TodoMsg
    | OnDomMsg DomMsg
    | SetView ViewType
    | UpdateNow Time
