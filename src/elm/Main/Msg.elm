module Main.Msg exposing (..)

import Dom
import DomTypes exposing (DomMsg)
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.TodoListMsg exposing (TodoMsg)
import Main.Types exposing (MainViewType)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import FunctionExtra.Operators exposing (..)
import Function


type NewTodoMsg
    = AddTodoClicked Dom.Id
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String Key


onNewTodo =
    { add = AddTodoClicked >> OnNewTodoMsg
    , input = NewTodoTextChanged >> OnNewTodoMsg
    , blur = NewTodoBlur |> OnNewTodoMsg
    , keyUp = (\a b -> OnNewTodoMsg (NewTodoKeyUp a b))
    }


type Msg
    = NoOp
    | OnAddTodoClicked Dom.Id
    | OnNewTodoTextChanged String
    | OnNewTodoBlur
    | OnNewTodoKeyUp String Key
      --
    | OnNewTodoMsg NewTodoMsg
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
    | SetMainViewType MainViewType
    | UpdateNow Time
