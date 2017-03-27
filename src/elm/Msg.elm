module Msg exposing (..)

import Dom
import Flow.Model exposing (FlowAction(..))
import Json.Decode
import Keyboard.Extra exposing (Key)
import Main.Types exposing (MainViewType)
import Navigation exposing (Location)
import Time exposing (Time)
import Todo exposing (Todo, TodoGroup, TodoId)
import FunctionExtra.Operators exposing (..)
import Function
import KeyboardExtra exposing (KeyboardEvent)
import Task
import TodoMsg exposing (TodoMsg)


type NewTodoMsg
    = AddTodoClicked
    | NewTodoTextChanged String
    | NewTodoBlur
    | NewTodoKeyUp String KeyboardEvent


type EditTodoMsg
    = EditTodoClicked Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent


onNewTodo =
    { addClicked = AddTodoClicked |> OnNewTodoMsg
    , input = NewTodoTextChanged >> OnNewTodoMsg
    , blur = NewTodoBlur |> OnNewTodoMsg
    , keyUp = NewTodoKeyUp >>> OnNewTodoMsg
    }


onEditTodo =
    { editClicked = EditTodoClicked >> OnEditTodoMsg
    , input = EditTodoTextChanged >> OnEditTodoMsg
    , blur = EditTodoBlur >> OnEditTodoMsg
    , keyUp = EditTodoKeyUp >>> OnEditTodoMsg
    }


toggleDone =
    TodoMsg.toggleDone >> OnTodoMsg


markDone =
    TodoMsg.markDone >> OnTodoMsg


toggleDelete =
    TodoMsg.toggleDelete >> OnTodoMsg


setGroup group =
    TodoMsg.setGroup group >> OnTodoMsg


setText text =
    TodoMsg.setText text >> OnTodoMsg


saveNewTodo =
    TodoMsg.saveNewTodo >> OnTodoMsg


splitNewTodoFrom =
    TodoMsg.splitNewTodoFrom >> OnTodoMsg


start =
    TodoMsg.start >> OnTodoMsg


stop =
    OnTodoMsg TodoMsg.stop


stopAndMarkDone =
    OnTodoMsg TodoMsg.StopAndMarkDone


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
