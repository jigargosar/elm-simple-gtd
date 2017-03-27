module Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import TodoListMsg exposing (TodoMsg)
import Main.Types exposing (MainViewType)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import FunctionExtra.Operators exposing (..)
import Function
import KeyboardExtra exposing (KeyboardEvent)
import Task


type NewTodoMsg
    = AddTodoClicked Dom.Id
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent


type EditTodoMsg
    = EditTodoClicked Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent


onNewTodo =
    { add = AddTodoClicked >> OnNewTodoMsg
    , input = NewTodoTextChanged >> OnNewTodoMsg
    , blur = NewTodoBlur |> OnNewTodoMsg
    , keyUp = NewTodoKeyUp >>> OnNewTodoMsg
    }


onEditTodo =
    { edit = EditTodoClicked >> OnEditTodoMsg
    , input = EditTodoTextChanged >> OnEditTodoMsg
    , blur = EditTodoBlur >> OnEditTodoMsg
    , keyUp = EditTodoKeyUp >>> OnEditTodoMsg
    }


todoMsg =
    { start = TodoListMsg.Start >> OnTodoMsg
    , stop = OnTodoMsg TodoListMsg.Stop
    , stopAndMarkDone = OnTodoMsg TodoListMsg.StopAndMarkDone
    }


type Msg
    = NoOp
    | OnNewTodoMsg NewTodoMsg
    | OnEditTodoMsg EditTodoMsg
      --
    | OnDeleteTodoClicked TodoId
    | OnTodoDoneClicked TodoId
    | OnSetTodoGroupClicked TodoGroup TodoId
      --
    | OnTodoMsg TodoMsg
    | SetMainViewType MainViewType
    | OnUpdateNow Time


msgToCmd : msg -> Cmd msg
msgToCmd x =
    Task.perform identity (Task.succeed x)
