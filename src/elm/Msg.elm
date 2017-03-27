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


type UpdateAction
    = ToggleDone
    | MarkDone
    | SetGroup TodoGroup
    | SetText String
    | ToggleDelete


type TodoMsg
    = UpdateTodoAt UpdateAction TodoId Time
    | UpdateTodo UpdateAction TodoId
    | AddNewTodo String
    | AddNewTodoAt String Time
    | SplitNewTodoFrom Todo
    | SplitNewTodoFromAt Todo Time
    | Start TodoId
    | Stop
    | StopAndMarkDone


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


toggleDone =
    UpdateTodo ToggleDone >> OnTodoMsg


markDone =
    UpdateTodo MarkDone >> OnTodoMsg


toggleDelete =
    UpdateTodo ToggleDelete >> OnTodoMsg


setGroup group =
    UpdateTodo (SetGroup group) >> OnTodoMsg


setText text =
    UpdateTodo (SetText text) >> OnTodoMsg


addNewTodo =
    AddNewTodo >> OnTodoMsg


splitNewTodoFrom =
    SplitNewTodoFrom >> OnTodoMsg


start =
    Start >> OnTodoMsg


stop =
    OnTodoMsg Stop


stopAndMarkDone =
    OnTodoMsg StopAndMarkDone


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
