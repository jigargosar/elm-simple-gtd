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
    = StartEditingTodo Todo
    | EditTodoTextChanged String
    | EditTodoBlur Todo
    | EditTodoKeyUp Todo KeyboardEvent


onNewTodo =
    { startAdding = AddTodoClicked |> OnNewTodoMsg
    , input = NewTodoTextChanged >> OnNewTodoMsg
    , blur = NewTodoBlur |> OnNewTodoMsg
    , keyUp = NewTodoKeyUp >>> OnNewTodoMsg
    }


startEditingTodo =
    StartEditingTodo >> OnEditTodoMsg


onEditTodo =
    { startEditing = startEditingTodo
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
    | OnTodoMsg TodoMsg
    | SetMainViewType MainViewType
    | OnUpdateNow Time
    | OnMsgList (List Msg)


msgToCmd : msg -> Cmd msg
msgToCmd msg =
    Task.perform identity (Task.succeed msg)
